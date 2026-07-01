-- =========================================================================
-- Migration: V9
-- Purpose: Add in-database documentation via COMMENT ON statements.
--          These comments are visible in psql (\d+, \dd), information_schema,
--          and any database tool — unlike SQL comments (--) which only
--          exist in source files.
--
-- This migration does NOT create or modify any database objects. It only
-- attaches metadata to objects created in V1–V8.
--
-- Run independently of the table creation transactions because COMMENT ON
-- statements cannot be rolled back past a prior DDL in the same transaction
-- without blocking concurrent access.
--
-- Designed by: kosail
-- Date: June 30, 2026
-- =========================================================================


-- =========================================================================
-- SCHEMAS
-- =========================================================================

COMMENT ON SCHEMA auth IS 'User accounts, profiles, authentication tracking, and project membership. Everything related to identity and user-to-project associations.';

COMMENT ON SCHEMA projects IS 'Project lifecycle — creation, archival, and deletion. Projects are the top-level organizational unit. Assets belong to projects. Users belong to projects via memberships.';

COMMENT ON SCHEMA tags IS 'Categorization system for assets. Tags can be global (visible across all projects) or scoped to a single project.';

COMMENT ON SCHEMA assets IS 'Core asset management. Defines logical assets, their versions, and the file upload pipeline with SHA-256 integrity verification.';

COMMENT ON SCHEMA permissions IS 'Defines the set of all possible permissions in the system using an action/target decomposition. Permissions are seeded during deployment and rarely change at runtime.';


-- =========================================================================
-- TABLES — auth
-- =========================================================================

COMMENT ON TABLE auth.app_user IS 'Core user account. One row per person in the system. Soft-delete strategy. Bootstrap user has created_by = NULL.';

COMMENT ON TABLE auth.login_history IS 'Immutable log of every login attempt — successful or failed. Append-only by design. Provides forensic data for security incident investigation.';

COMMENT ON TABLE auth.app_user_profile IS 'One-to-one extension of app_user. Stores display-oriented fields not needed for authentication queries. No created_at/created_by: profile creation is a side effect of user creation.';

COMMENT ON TABLE auth.project_membership IS 'Which users belong to which projects. Entity with its own identity because permissions reference it via project_membership_permission.';

COMMENT ON TABLE auth.project_membership_permission IS 'Granular permissions assigned to a specific user within a specific project. Bridges project_membership to permissions.permission. Enables per-project permission assignment.';


-- =========================================================================
-- COLUMNS — auth.app_user
-- =========================================================================

COMMENT ON COLUMN auth.app_user.id IS 'Surrogate primary key. No business meaning.';
COMMENT ON COLUMN auth.app_user.first_name IS 'Given name. Separated from last_name so the UI can render independently without string parsing.';
COMMENT ON COLUMN auth.app_user.last_name IS 'Family name. Separated from first_name so the UI can render independently without string parsing.';
COMMENT ON COLUMN auth.app_user.username IS 'Login identifier. Unique across all users, including soft-deleted.';
COMMENT ON COLUMN auth.app_user.email IS 'Contact and credential email. Unique globally, including soft-deleted. Note: email uniqueness includes deleted users, so an email cannot be reused even after account deletion.';
COMMENT ON COLUMN auth.app_user.password_hash IS 'BCrypt or Argon2 output. Never stores plaintext passwords.';
COMMENT ON COLUMN auth.app_user.token_version IS 'Stateless JWT kill switch. Incremented on password change and "sign out everywhere". Any JWT with a lower token_version is rejected by the auth filter.';
COMMENT ON COLUMN auth.app_user.last_seen_at IS 'Throttled heartbeat. Updated on authenticated requests (at most once every 5 minutes). Used for "users inactive for 90 days" reports.';
COMMENT ON COLUMN auth.app_user.created_at IS 'Row creation timestamp. Set on first insert.';
COMMENT ON COLUMN auth.app_user.updated_at IS 'Last modification timestamp. Maintained by trigger trg_auth_app_user_update in V8.';
COMMENT ON COLUMN auth.app_user.deleted_at IS 'Soft-delete marker. NULL = active user. Non-NULL = user is deactivated and cannot log in.';
COMMENT ON COLUMN auth.app_user.created_by IS 'Who created this user. NULL for bootstrap user or self-registration. FK to auth.app_user(id).';
COMMENT ON COLUMN auth.app_user.updated_by IS 'Who last modified this user. NULL for bootstrap user or self-registration. FK to auth.app_user(id).';
COMMENT ON COLUMN auth.app_user.deleted_by IS 'Who soft-deleted this user. FK to auth.app_user(id).';


-- =========================================================================
-- COLUMNS — auth.login_history
-- =========================================================================

COMMENT ON COLUMN auth.login_history.id IS 'Surrogate primary key.';
COMMENT ON COLUMN auth.login_history.user_id IS 'The user attempting to log in. FK to auth.app_user(id). Anonymous login failures are not tracked in MVP.';
COMMENT ON COLUMN auth.login_history.ip_address IS 'Origin IP address. Stored as INET for correct sorting, CIDR matching, and IP family (v4/v6) awareness.';
COMMENT ON COLUMN auth.login_history.user_agent IS 'User-Agent header from the login request. Max 255 characters; longer values truncated by application.';
COMMENT ON COLUMN auth.login_history.success IS 'Outcome of the attempt. TRUE = credentials accepted. FALSE = rejected. Used for brute-force detection queries.';
COMMENT ON COLUMN auth.login_history.attempt_at IS 'When the attempt occurred. Server-side timestamp, not client-supplied.';


-- =========================================================================
-- COLUMNS — auth.app_user_profile
-- =========================================================================

COMMENT ON COLUMN auth.app_user_profile.id IS 'Surrogate primary key.';
COMMENT ON COLUMN auth.app_user_profile.user_id IS 'Owner of this profile. FK to auth.app_user(id). One-to-one relationship.';
COMMENT ON COLUMN auth.app_user_profile.profile_picture_url IS 'URL or key reference to profile picture in S3. Nullable because a user can exist without a picture.';
COMMENT ON COLUMN auth.app_user_profile.user_description IS 'Self-written bio or description. Free text, max 255 characters.';
COMMENT ON COLUMN auth.app_user_profile.updated_at IS 'Last modification timestamp. Maintained by trigger trg_auth_app_user_profile_update in V8. No created_at column: profile creation is a side effect of user creation.';
COMMENT ON COLUMN auth.app_user_profile.deleted_at IS 'Soft-delete marker. Set when the corresponding app_user is soft-deleted. Mirrors user deleted_at — enforced at application layer.';
COMMENT ON COLUMN auth.app_user_profile.updated_by IS 'Who last modified this profile. FK to auth.app_user(id). NOT NULL even for system-initiated profile creation.';


-- =========================================================================
-- COLUMNS — auth.project_membership
-- =========================================================================

COMMENT ON COLUMN auth.project_membership.id IS 'Surrogate primary key. Referenced by project_membership_permission.';
COMMENT ON COLUMN auth.project_membership.user_id IS 'The user who is a member. FK to auth.app_user(id).';
COMMENT ON COLUMN auth.project_membership.project_id IS 'The project they belong to. FK to projects.project(id).';
COMMENT ON COLUMN auth.project_membership.created_at IS 'When the membership was granted.';
COMMENT ON COLUMN auth.project_membership.updated_at IS 'Last modification timestamp. Maintained by trigger trg_auth_project_membership_update in V8.';
COMMENT ON COLUMN auth.project_membership.deleted_at IS 'NULL = active membership. Set when user is removed from the project.';
COMMENT ON COLUMN auth.project_membership.created_by IS 'Who granted this membership. FK to auth.app_user(id). NOT NULL: membership is always granted by an existing user.';
COMMENT ON COLUMN auth.project_membership.updated_by IS 'Who last modified this membership. FK to auth.app_user(id).';
COMMENT ON COLUMN auth.project_membership.deleted_by IS 'Who removed this membership. NULL for active memberships. FK to auth.app_user(id).';


-- =========================================================================
-- COLUMNS — auth.project_membership_permission
-- =========================================================================

COMMENT ON COLUMN auth.project_membership_permission.id IS 'Surrogate primary key.';
COMMENT ON COLUMN auth.project_membership_permission.user_project_id IS 'The membership this permission is scoped to. FK to auth.project_membership(id).';
COMMENT ON COLUMN auth.project_membership_permission.permission_id IS 'The specific permission granted. FK to permissions.permission(id).';
COMMENT ON COLUMN auth.project_membership_permission.created_at IS 'When the permission was granted.';
COMMENT ON COLUMN auth.project_membership_permission.updated_at IS 'Last modification timestamp. Maintained by trigger trg_auth_project_membership_permission_update in V8.';
COMMENT ON COLUMN auth.project_membership_permission.deleted_at IS 'NULL = active grant. Set when the permission is revoked.';
COMMENT ON COLUMN auth.project_membership_permission.created_by IS 'Who granted this permission. FK to auth.app_user(id).';
COMMENT ON COLUMN auth.project_membership_permission.updated_by IS 'Who last modified this grant. FK to auth.app_user(id).';
COMMENT ON COLUMN auth.project_membership_permission.deleted_by IS 'Who revoked this permission. NULL for active grants. FK to auth.app_user(id).';


-- =========================================================================
-- TABLES — projects
-- =========================================================================

COMMENT ON TABLE projects.project IS 'A game or software project (e.g., "Pet Society 2"). Top-level container for all assets, versions, and memberships. Tombstone semantics on DELETED status: metadata preserved but child data purged (assets, memberships).';


-- =========================================================================
-- COLUMNS — projects.project
-- =========================================================================

COMMENT ON COLUMN projects.project.id IS 'Surrogate primary key.';
COMMENT ON COLUMN projects.project.project_name IS 'Display name. Unique among non-deleted projects. Max 128 characters.';
COMMENT ON COLUMN projects.project.slug IS 'URL-friendly identifier. Lowercase, hyphenated, no special characters. Unique among non-deleted projects. Example: "Pet Society 2" → "pet-society-2".';
COMMENT ON COLUMN projects.project.project_external_url IS 'Optional link to external resources (GitLab repository, Confluence page, shared drive). Max 512 characters.';
COMMENT ON COLUMN projects.project.project_icon_url IS 'Optional icon URL. Points to S3/MinIO object key. Max 512 characters.';
COMMENT ON COLUMN projects.project.description IS 'Free-text project description. TEXT type with no length limit. Application UI should enforce a reasonable maximum.';
COMMENT ON COLUMN projects.project.status IS 'Lifecycle state. ACTIVE = normal operation. ARCHIVED = read-only, reversible. DELETED = tombstone, child data purged, partially reversible (metadata only).';
COMMENT ON COLUMN projects.project.created_at IS 'When the project was created.';
COMMENT ON COLUMN projects.project.updated_at IS 'Last modification timestamp. Maintained by trigger trg_project_project_update in V8.';
COMMENT ON COLUMN projects.project.archived_at IS 'When the project was set to ARCHIVED status. NULL for ACTIVE and DELETED projects.';
COMMENT ON COLUMN projects.project.deleted_at IS 'Tombstone timestamp. When the project was set to DELETED status. Dependent data (memberships, assets, versions) is physically destroyed. NULL for ACTIVE and ARCHIVED projects.';
COMMENT ON COLUMN projects.project.created_by IS 'Who created the project. FK to auth.app_user(id). NOT NULL: every project has a creator.';
COMMENT ON COLUMN projects.project.updated_by IS 'Who last modified the project. FK to auth.app_user(id).';
COMMENT ON COLUMN projects.project.archived_by IS 'Who archived the project. NULL for ACTIVE and DELETED projects. FK to auth.app_user(id).';
COMMENT ON COLUMN projects.project.deleted_by IS 'Who deleted the project. NULL for ACTIVE and ARCHIVED projects. FK to auth.app_user(id).';


-- =========================================================================
-- TABLES — tags
-- =========================================================================

COMMENT ON TABLE tags.tag IS 'A single tag entity. Can be global (project_id IS NULL) or project-scoped (project_id IS NOT NULL). Tags are created at runtime by authorized users, not seeded during deployment. Scope cannot change after creation.';


-- =========================================================================
-- COLUMNS — tags.tag
-- =========================================================================

COMMENT ON COLUMN tags.tag.id IS 'Surrogate primary key. No business meaning.';
COMMENT ON COLUMN tags.tag.tag_name IS 'Display name (e.g., "UI", "Character", "Environment", "Animation"). Case-sensitive. Uniqueness depends on scope: global tags are globally unique, project-scoped tags are unique within their project.';
COMMENT ON COLUMN tags.tag.project_id IS 'Scope of the tag. NULL = global tag, visible across all projects. NOT NULL = project-scoped tag, only usable within that project. Cannot change after creation. FK to projects.project(id).';
COMMENT ON COLUMN tags.tag.created_at IS 'When the tag was created.';
COMMENT ON COLUMN tags.tag.updated_at IS 'Last modification timestamp. Maintained by trigger trg_tags_tag_update in V8.';
COMMENT ON COLUMN tags.tag.deleted_at IS 'Soft-delete marker. NULL = active tag. Set when the tag should no longer appear in assignment UIs.';
COMMENT ON COLUMN tags.tag.created_by IS 'Who created the tag. FK to auth.app_user(id). NOT NULL: tags are always created by an authenticated user.';
COMMENT ON COLUMN tags.tag.updated_by IS 'Who last modified the tag. FK to auth.app_user(id).';
COMMENT ON COLUMN tags.tag.deleted_by IS 'Who soft-deleted this tag. FK to auth.app_user(id).';


-- =========================================================================
-- TABLES — assets
-- =========================================================================

COMMENT ON TABLE assets.asset IS 'Logical representation of an asset (e.g., "Character Portrait"). Not a file. One row per conceptual asset within a project. Soft-deleted. asset_name and asset_codename are unique within a project (see partial indexes in V7).';

COMMENT ON TABLE assets.asset_version IS 'A specific version of an asset. Immutable after creation. Tracks the Draft → Published lifecycle. Two concurrent drafts for the same asset are allowed; the user chooses which to publish. Once PUBLISHED, a version is immutable.';

COMMENT ON TABLE assets.asset_file IS 'Tracks the upload and SHA-256 verification of a single binary file. Decoupled from asset_version to separate the upload pipeline state machine (UPLOADING → VERIFYING → ACCEPTED/REJECTED/FAILED) from the versioning model. Append-only: rows are never soft-deleted or hard-deleted.';


-- =========================================================================
-- COLUMNS — assets.asset
-- =========================================================================

COMMENT ON COLUMN assets.asset.id IS 'Surrogate primary key. Referenced by asset_version.';
COMMENT ON COLUMN assets.asset.project_id IS 'The project this asset belongs to. FK to projects.project(id). Every asset lives inside exactly one project.';
COMMENT ON COLUMN assets.asset.asset_name IS 'Human-readable display name (e.g., "Main Character Portrait"). Unique within the project (see partial index in V7).';
COMMENT ON COLUMN assets.asset.asset_codename IS 'Machine-readable internal identifier (e.g., "char_main_portrait"). Used by developers and scripts. Unique within the project (see partial index in V7).';
COMMENT ON COLUMN assets.asset.asset_description IS 'Free-text description. TEXT type with no length limit. Artists may provide detailed technical notes.';
COMMENT ON COLUMN assets.asset.asset_icon_url IS 'Optional thumbnail or icon URL. Points to S3/MinIO object path. Max 512 characters.';
COMMENT ON COLUMN assets.asset.created_at IS 'When the asset row was created (first draft initiated).';
COMMENT ON COLUMN assets.asset.updated_at IS 'Last modification timestamp. Maintained by trigger trg_assets_asset_update in V8.';
COMMENT ON COLUMN assets.asset.deleted_at IS 'Soft-delete marker. NULL = active asset. When set, all versions are also soft-deleted (application-level coordination).';
COMMENT ON COLUMN assets.asset.created_by IS 'Who created the asset. FK to auth.app_user(id).';
COMMENT ON COLUMN assets.asset.updated_by IS 'Who last modified the asset. FK to auth.app_user(id).';
COMMENT ON COLUMN assets.asset.deleted_by IS 'Who soft-deleted this asset. FK to auth.app_user(id).';


-- =========================================================================
-- COLUMNS — assets.asset_version
-- =========================================================================

COMMENT ON COLUMN assets.asset_version.id IS 'Surrogate primary key. Referenced by asset_file.';
COMMENT ON COLUMN assets.asset_version.asset_id IS 'The asset this version belongs to. FK to assets.asset(id).';
COMMENT ON COLUMN assets.asset_version.file_id IS 'Denormalized reference to the current accepted file for this version. FK to assets.asset_file(id). Performance shortcut to avoid querying asset_file for the latest file. NULL when no file has been accepted yet.';
COMMENT ON COLUMN assets.asset_version.version_number IS 'Assigned at publish time. MAX(version_number) + 1 for the parent asset. NULL for DRAFT versions. First published version = 1.';
COMMENT ON COLUMN assets.asset_version.status IS 'Lifecycle state. DRAFT = upload in progress or pending review. PUBLISHED = available for download, immutable. One-way transition: DRAFT → PUBLISHED.';
COMMENT ON COLUMN assets.asset_version.version_notes IS 'Optional free-text notes about changes in this version (e.g., "Fixed lighting, reduced poly count by 15%").';
COMMENT ON COLUMN assets.asset_version.created_at IS 'When the version row was created (draft initiated).';
COMMENT ON COLUMN assets.asset_version.updated_at IS 'Last modification timestamp. Maintained by trigger trg_assets_asset_version_update in V8.';
COMMENT ON COLUMN assets.asset_version.published_at IS 'When status changed from DRAFT to PUBLISHED. NULL for DRAFT versions.';
COMMENT ON COLUMN assets.asset_version.deleted_at IS 'Soft-delete marker. NULL = active version.';
COMMENT ON COLUMN assets.asset_version.created_by IS 'Who created this version. FK to auth.app_user(id).';
COMMENT ON COLUMN assets.asset_version.updated_by IS 'Who last modified this version. FK to auth.app_user(id).';
COMMENT ON COLUMN assets.asset_version.deleted_by IS 'Who soft-deleted this version. FK to auth.app_user(id).';


-- =========================================================================
-- COLUMNS — assets.asset_file
-- =========================================================================

COMMENT ON COLUMN assets.asset_file.id IS 'Surrogate primary key.';
COMMENT ON COLUMN assets.asset_file.asset_version_id IS 'The version this file belongs to. FK to assets.asset_version(id).';
COMMENT ON COLUMN assets.asset_file.file_name IS 'Original filename as provided by the user during upload (e.g., "character_v5_final.psd"). Informational only.';
COMMENT ON COLUMN assets.asset_file.file_size IS 'File size in bytes. Provided by the frontend and validated against S3 object size during verification.';
COMMENT ON COLUMN assets.asset_file.content_type IS 'MIME type of the file (e.g., "image/png", "application/octet-stream"). Used to set Content-Type in download responses.';
COMMENT ON COLUMN assets.asset_file.expected_sha256_hash IS 'SHA-256 hash reported by the frontend before upload. Hex-encoded, 64 characters. Compared against calculated_sha256_hash after upload.';
COMMENT ON COLUMN assets.asset_file.s3_key IS 'Deterministic S3/MinIO object key. Globally unique. Format: projects/{project_id}/assets/{asset_id}/versions/{version_id}/{file_name}.';
COMMENT ON COLUMN assets.asset_file.calculated_sha256_hash IS 'SHA-256 hash computed by the backend from the uploaded S3 object. NULL during UPLOADING, VERIFYING, and FAILED states. Hex-encoded, 64 characters.';
COMMENT ON COLUMN assets.asset_file.status IS 'Upload pipeline state. UPLOADING = transferring to S3. VERIFYING = computing hash. FAILED = technical error. ACCEPTED = hash match. REJECTED = hash mismatch.';
COMMENT ON COLUMN assets.asset_file.rejection_reason IS 'Human-readable reason for rejection. Non-NULL only when status = REJECTED. Example: "File checksum mismatch. Expected: abc123, Calculated: def456".';
COMMENT ON COLUMN assets.asset_file.created_at IS 'Row creation timestamp. Set when the upload is initiated (UPLOADING state). Not the same as upload completion time.';
COMMENT ON COLUMN assets.asset_file.upload_completed_at IS 'When the file bytes finished transferring to S3. Set during UPLOADING → VERIFYING transition. NULL during UPLOADING state.';
COMMENT ON COLUMN assets.asset_file.verified_at IS 'When hash verification concluded. Set when status becomes ACCEPTED or REJECTED. NULL during UPLOADING and VERIFYING states.';
COMMENT ON COLUMN assets.asset_file.uploaded_by IS 'Who initiated the upload. FK to auth.app_user(id).';


-- =========================================================================
-- TABLES — permissions
-- =========================================================================

COMMENT ON TABLE permissions.action_type IS 'Enumeration of actions a user can perform. Example values: CREATE, READ, UPDATE, DELETE, PUBLISH, DOWNLOAD, UPLOAD. Seeded during deployment, not created at runtime.';

COMMENT ON TABLE permissions.action_target IS 'Enumeration of resource types an action can apply to. Example values: PROJECT, ASSET, ASSET_VERSION, USER, MEMBERSHIP. Seeded during deployment, not created at runtime.';

COMMENT ON TABLE permissions.permission IS 'The Cartesian product of action_type × action_target that defines every possible permission in the system. Referenced by project_membership_permission to grant specific permissions.';


-- =========================================================================
-- COLUMNS — permissions.action_type
-- =========================================================================

COMMENT ON COLUMN permissions.action_type.id IS 'Surrogate primary key. SMALLINT because the dataset is bounded (~15 action types).';
COMMENT ON COLUMN permissions.action_type.action_name IS 'Human-readable action name. Used in authorization annotations and permission checks.';
COMMENT ON COLUMN permissions.action_type.created_at IS 'Set during migration execution. Not an application-level timestamp.';
COMMENT ON COLUMN permissions.action_type.updated_at IS 'Set during migration execution if seed data is modified. Not an application-level timestamp.';
COMMENT ON COLUMN permissions.action_type.deleted_at IS 'Reserved. Unlikely to be used for seed data that is never removed at runtime.';


-- =========================================================================
-- COLUMNS — permissions.action_target
-- =========================================================================

COMMENT ON COLUMN permissions.action_target.id IS 'Surrogate primary key. SMALLINT because the dataset is bounded (~10-20 action targets).';
COMMENT ON COLUMN permissions.action_target.action_target IS 'Human-readable target name. Matches the resource type string used in authorization logic.';
COMMENT ON COLUMN permissions.action_target.created_at IS 'Set during migration execution. Not an application-level timestamp.';
COMMENT ON COLUMN permissions.action_target.updated_at IS 'Set during migration execution if seed data is modified. Not an application-level timestamp.';
COMMENT ON COLUMN permissions.action_target.deleted_at IS 'Reserved. Unlikely to be used for seed data that is never removed at runtime.';


-- =========================================================================
-- COLUMNS — permissions.permission
-- =========================================================================

COMMENT ON COLUMN permissions.permission.id IS 'Surrogate primary key. BIGINT for consistency with other entity tables, even though the Cartesian product is small.';
COMMENT ON COLUMN permissions.permission.action_type_id IS 'The action this permission represents. FK to permissions.action_type(id).';
COMMENT ON COLUMN permissions.permission.action_target_id IS 'The resource type this permission applies to. FK to permissions.action_target(id).';
COMMENT ON COLUMN permissions.permission.created_at IS 'Set during migration execution. Not an application-level timestamp.';
COMMENT ON COLUMN permissions.permission.updated_at IS 'Set during migration execution if seed data is modified. Not an application-level timestamp.';
COMMENT ON COLUMN permissions.permission.deleted_at IS 'Reserved. Unlikely to be used for seed data that is never removed at runtime.';

--
-- -- =========================================================================
-- -- CONSTRAINTS
-- -- =========================================================================
--
-- -- =========================================================================
-- -- PRIMARY KEY constraints
-- -- =========================================================================
--
-- COMMENT ON CONSTRAINT pk_app_user ON auth.app_user IS 'Primary key for auth.app_user.';
-- COMMENT ON CONSTRAINT pk_login_history ON auth.login_history IS 'Primary key for auth.login_history.';
-- COMMENT ON CONSTRAINT pk_app_user_profile ON auth.app_user_profile IS 'Primary key for auth.app_user_profile.';
-- COMMENT ON CONSTRAINT pk_project_membership ON auth.project_membership IS 'Primary key for auth.project_membership.';
-- COMMENT ON CONSTRAINT pk_project_membership_permission ON auth.project_membership_permission IS 'Primary key for auth.project_membership_permission.';
-- COMMENT ON CONSTRAINT pk_project ON projects.project IS 'Primary key for projects.project.';
-- COMMENT ON CONSTRAINT pk_tag ON tags.tag IS 'Primary key for tags.tag.';
-- COMMENT ON CONSTRAINT pk_asset ON assets.asset IS 'Primary key for assets.asset.';
-- COMMENT ON CONSTRAINT pk_asset_version ON assets.asset_version IS 'Primary key for assets.asset_version.';
-- COMMENT ON CONSTRAINT pk_assets_asset_file ON assets.asset_file IS 'Primary key for assets.asset_file.';
-- COMMENT ON CONSTRAINT pk_action_type ON permissions.action_type IS 'Primary key for permissions.action_type.';
-- COMMENT ON CONSTRAINT pk_action_target ON permissions.action_target IS 'Primary key for permissions.action_target.';
-- COMMENT ON CONSTRAINT pk_permission ON permissions.permission IS 'Primary key for permissions.permission.';
--
--
-- -- =========================================================================
-- -- UNIQUE constraints
-- -- =========================================================================
--
-- COMMENT ON CONSTRAINT uq_app_user_username ON auth.app_user IS 'Ensures usernames are unique across all users, including soft-deleted.';
-- COMMENT ON CONSTRAINT uq_app_user_email ON auth.app_user IS 'Ensures emails are unique across all users, including soft-deleted.';
-- COMMENT ON CONSTRAINT uq_action_name ON permissions.action_type IS 'Ensures each action type name is unique.';
-- COMMENT ON CONSTRAINT uq_action_target ON permissions.action_target IS 'Ensures each action target name is unique.';
-- COMMENT ON CONSTRAINT uq_permission_action_type_action_target ON permissions.permission IS 'Ensures each (action_type_id, action_target_id) pair appears at most once.';
-- COMMENT ON CONSTRAINT uq_asset_file_s3_key ON assets.asset_file IS 'Ensures S3 keys are globally unique. Enforces the never-overwrite principle at the database level.';
--
--
-- -- =========================================================================
-- -- CHECK constraints
-- -- =========================================================================
--
-- COMMENT ON CONSTRAINT chk_project_status ON projects.project IS 'Ensures status is one of: ACTIVE, ARCHIVED, DELETED.';
-- COMMENT ON CONSTRAINT chk_asset_version_status ON assets.asset_version IS 'Ensures version status is one of: DRAFT, PUBLISHED.';
-- COMMENT ON CONSTRAINT chk_asset_file_status ON assets.asset_file IS 'Ensures file status is one of: UPLOADING, VERIFYING, FAILED, ACCEPTED, REJECTED.';
-- COMMENT ON CONSTRAINT chk_asset_file_status_consistency ON assets.asset_file IS 'Ensures calculated_sha256_hash is NULL during upload/verification and NOT NULL when a verdict (ACCEPTED/REJECTED) has been reached. Prevents logically inconsistent rows.';
--
--
-- -- =========================================================================
-- -- FOREIGN KEY constraints
-- -- =========================================================================
--
-- COMMENT ON CONSTRAINT fk_auth_app_user_created_by ON auth.app_user IS 'Tracks which user created this user. Self-referencing. NULL permitted for bootstrap.';
-- COMMENT ON CONSTRAINT fk_auth_app_user_updated_by ON auth.app_user IS 'Tracks which user last updated this user. Self-referencing. NULL permitted for bootstrap.';
-- COMMENT ON CONSTRAINT fk_auth_app_user_deleted_by ON auth.app_user IS 'Tracks which user soft-deleted this user. Self-referencing.';
--
-- COMMENT ON CONSTRAINT fk_auth_app_user_profile_user ON auth.app_user_profile IS 'Links profile to user. One-to-one relationship enforced by application.';
-- COMMENT ON CONSTRAINT fk_auth_app_user_profile_updated_by ON auth.app_user_profile IS 'Tracks who last modified the profile.';
--
-- COMMENT ON CONSTRAINT fk_auth_project_membership_user ON auth.project_membership IS 'Links membership to the user who is a member.';
-- COMMENT ON CONSTRAINT fk_auth_project_membership_project ON auth.project_membership IS 'Links membership to the project.';
-- COMMENT ON CONSTRAINT fk_auth_project_membership_created_by ON auth.project_membership IS 'Tracks who granted the membership.';
-- COMMENT ON CONSTRAINT fk_auth_project_membership_updated_by ON auth.project_membership IS 'Tracks who last modified the membership.';
-- COMMENT ON CONSTRAINT fk_auth_project_membership_deleted_by ON auth.project_membership IS 'Tracks who removed the membership.';
--
-- COMMENT ON CONSTRAINT fk_auth_project_membership_permission_user_project ON auth.project_membership_permission IS 'Links permission grant to the specific membership.';
-- COMMENT ON CONSTRAINT fk_auth_project_membership_permission_permission ON auth.project_membership_permission IS 'Links permission grant to the specific permission definition.';
-- COMMENT ON CONSTRAINT fk_auth_project_membership_permission_created_by ON auth.project_membership_permission IS 'Tracks who granted the permission.';
-- COMMENT ON CONSTRAINT fk_auth_project_membership_permission_updated_by ON auth.project_membership_permission IS 'Tracks who last modified the grant.';
-- COMMENT ON CONSTRAINT fk_auth_project_membership_permission_deleted_by ON auth.project_membership_permission IS 'Tracks who revoked the permission.';
--
-- COMMENT ON CONSTRAINT fk_projects_project_created_by ON projects.project IS 'Tracks who created the project.';
-- COMMENT ON CONSTRAINT fk_projects_project_updated_by ON projects.project IS 'Tracks who last modified the project.';
-- COMMENT ON CONSTRAINT fk_projects_project_archived_by ON projects.project IS 'Tracks who archived the project.';
-- COMMENT ON CONSTRAINT fk_projects_project_deleted_by ON projects.project IS 'Tracks who deleted the project.';
--
-- COMMENT ON CONSTRAINT fk_tags_tag_project ON tags.tag IS 'Links tag to project scope. NULL = global tag.';
-- COMMENT ON CONSTRAINT fk_tags_tag_created_by ON tags.tag IS 'Tracks who created the tag.';
-- COMMENT ON CONSTRAINT fk_tags_tag_updated_by ON tags.tag IS 'Tracks who last modified the tag.';
-- COMMENT ON CONSTRAINT fk_tags_tag_deleted_by ON tags.tag IS 'Tracks who soft-deleted the tag.';
--
-- COMMENT ON CONSTRAINT fk_assets_asset_project_id ON assets.asset IS 'Links asset to its project.';
-- COMMENT ON CONSTRAINT fk_assets_asset_created_by ON assets.asset IS 'Tracks who created the asset.';
-- COMMENT ON CONSTRAINT fk_assets_asset_updated_by ON assets.asset IS 'Tracks who last modified the asset.';
-- COMMENT ON CONSTRAINT fk_assets_asset_deleted_by ON assets.asset IS 'Tracks who soft-deleted the asset.';
--
-- COMMENT ON CONSTRAINT fk_assets_asset_version_asset ON assets.asset_version IS 'Links version to its asset.';
-- COMMENT ON CONSTRAINT fk_asset_asset_version_file_id ON assets.asset_version IS 'Denormalized link to the current accepted file. Performance shortcut.';
-- COMMENT ON CONSTRAINT fk_assets_asset_version_created_by ON assets.asset_version IS 'Tracks who created the version.';
-- COMMENT ON CONSTRAINT fk_assets_asset_version_updated_by ON assets.asset_version IS 'Tracks who last modified the version.';
-- COMMENT ON CONSTRAINT fk_assets_asset_version_deleted_by ON assets.asset_version IS 'Tracks who soft-deleted the version.';
--
-- COMMENT ON CONSTRAINT fk_assets_asset_file_version ON assets.asset_file IS 'Links file to its version.';
-- COMMENT ON CONSTRAINT fk_assets_asset_file_uploaded_by ON assets.asset_file IS 'Tracks who initiated the upload.';
--
-- COMMENT ON CONSTRAINT fk_permissions_permission_action_type ON permissions.permission IS 'Links permission to its action type.';
-- COMMENT ON CONSTRAINT fk_permissions_permission_action_target ON permissions.permission IS 'Links permission to its action target.';
--
--
-- -- =========================================================================
-- -- INDEXES
-- -- =========================================================================
--
-- -- AUTH INDEXES
-- COMMENT ON INDEX idx_auth_project_membership_user_project IS 'Enforces one active membership per user per project. Partial index: excludes soft-deleted memberships so the same user can be re-added.';
-- COMMENT ON INDEX idx_auth_project_membership_permission_user_project IS 'Enforces a permission cannot be granted twice to the same membership. Partial index: excludes soft-deleted grants.';
-- COMMENT ON INDEX idx_auth_project_membership_permission_permission IS 'Supports reverse lookup: show all memberships that have permission X. Used when a permission is revoked globally.';
--
-- -- PROJECTS INDEXES
-- COMMENT ON INDEX uq_projects_project_name IS 'Uniqueness index for project_name across non-deleted projects. Tombstones are excluded: a deleted project releases its name.';
-- COMMENT ON INDEX uq_projects_project_slug IS 'Uniqueness index for slug across non-deleted projects. Same tombstone exclusion pattern as project_name.';
-- COMMENT ON INDEX idx_projects_project_archived_at IS 'Supports "list all archived projects" queries. Partial index: only covers rows with archived_at IS NOT NULL.';
-- COMMENT ON INDEX idx_projects_project_status IS 'Supports filtered queries for ACTIVE or ARCHIVED projects. Excludes tombstone rows (deleted_at IS NOT NULL) because most operational queries filter them out.';
--
-- -- TAGS INDEXES
-- COMMENT ON INDEX idx_tags_tag_name_global_uniqueness IS 'Enforces global tag name uniqueness. Partial index: only covers non-deleted tags with NULL project_id (global scope).';
-- COMMENT ON INDEX idx_tags_tag_name_per_project IS 'Enforces per-project tag name uniqueness. Partial index: only covers non-deleted tags with NOT NULL project_id (project-scoped).';
--
-- -- ASSETS INDEXES
-- COMMENT ON INDEX uq_asset_name_per_project IS 'Enforces unique asset name per project. Partial index: excludes soft-deleted assets.';
-- COMMENT ON INDEX uq_asset_codename_per_project IS 'Enforces unique asset codename per project. Partial index: excludes soft-deleted assets.';
--
--
-- -- =========================================================================
-- -- TRIGGER FUNCTION
-- -- =========================================================================
--
-- COMMENT ON FUNCTION trigger_update_timestamp() IS 'Sets NEW.updated_at to NOW() on BEFORE UPDATE for any row. Used by all updated_at triggers to avoid application-level timestamp management.';
--
--
-- -- =========================================================================
-- -- TRIGGERS
-- -- =========================================================================
--
-- COMMENT ON TRIGGER trg_auth_app_user_update ON auth.app_user IS 'Automatically sets updated_at to NOW() on row update.';
-- COMMENT ON TRIGGER trg_auth_app_user_profile_update ON auth.app_user_profile IS 'Automatically sets updated_at to NOW() on row update.';
-- COMMENT ON TRIGGER trg_auth_project_membership_update ON auth.project_membership IS 'Automatically sets updated_at to NOW() on row update.';
-- COMMENT ON TRIGGER trg_auth_project_membership_permission_update ON auth.project_membership_permission IS 'Automatically sets updated_at to NOW() on row update.';
--
-- COMMENT ON TRIGGER trg_project_project_update ON projects.project IS 'Automatically sets updated_at to NOW() on row update.';
--
-- COMMENT ON TRIGGER trg_tags_tag_update ON tags.tag IS 'Automatically sets updated_at to NOW() on row update.';
--
-- COMMENT ON TRIGGER trg_assets_asset_update ON assets.asset IS 'Automatically sets updated_at to NOW() on row update.';
-- COMMENT ON TRIGGER trg_assets_asset_version_update ON assets.asset_version IS 'Automatically sets updated_at to NOW() on row update.';
--
-- COMMENT ON TRIGGER trg_permissions_action_type_update ON permissions.action_type IS 'Automatically sets updated_at to NOW() on row update.';
-- COMMENT ON TRIGGER trg_permissions_action_target_update ON permissions.action_target IS 'Automatically sets updated_at to NOW() on row update.';
-- COMMENT ON TRIGGER trg_permissions_permission_update ON permissions.permission IS 'Automatically sets updated_at to NOW() on row update.';
