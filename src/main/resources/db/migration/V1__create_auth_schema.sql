-- =========================================================================
-- Schema: auth
-- Purpose: User accounts, profiles, authentication tracking, and project
--          membership. Everything related to identity and user-to-project
--          associations.
--
-- Designed by: kosail
-- Date: June 29, 2026
-- =========================================================================

BEGIN TRANSACTION;

CREATE SCHEMA IF NOT EXISTS auth;

-- =========================================================================
-- Table: auth.app_user
-- Purpose: Core user account. One row per person in the system.
--
-- Deletion strategy: Soft delete (deleted_at). Hard deletes are prevented
-- by ON DELETE RESTRICT on all foreign keys.
--
-- Bootstrap note: The first user in the system will have created_by = NULL
-- because no user exists to be the creator. This is intentional. The FK on
-- created_by permits NULL for exactly this case.
-- =========================================================================
CREATE TABLE auth.app_user (
    -- Surrogate primary key. No business meaning.
    id              BIGINT GENERATED ALWAYS AS IDENTITY,

    public_id       UUID NOT NULL DEFAULT uuidv7(),

    -- Display name components. Separated (not a single "name" column) so the
    -- UI can render them independently without string parsing.
    first_name      VARCHAR(128) NOT NULL,
    last_name       VARCHAR(128) NOT NULL,

    -- Login identifier. Unique across all users (including soft-deleted).
    username        VARCHAR(128) NOT NULL,

    -- Contact and credential. email is unique globally (including soft-deleted).
    -- password_hash stores the output of BCrypt or Argon2 — never plaintext.
    email           VARCHAR(128) NOT NULL,
    password_hash   VARCHAR(128) NOT NULL,

    -- Stateless JWT kill switch. Incremented on password change and
    -- "sign out everywhere". Any JWT with a lower token_version is rejected
    -- by the auth filter. Default 0 so initial tokens work immediately.
    token_version   INTEGER NOT NULL DEFAULT 0,

    -- Throttled heartbeat. Updated on authenticated requests (at most once
    -- every 5 minutes). Used for "users inactive for 90 days" reports.
    -- Initialized to CURRENT_TIMESTAMP so a new user is considered active.
    last_seen_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Record lifecycle timestamps (operational metadata, not audit trail).
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at      TIMESTAMPTZ, -- NULL = active user

    -- Actor tracking. Self-referencing FK to auth.app_user(id).
    -- NULL means: system-created (first bootstrap user), or self-registration.
    -- NOT NULL once a Producer/Admin creates subsequent users.
    created_by      BIGINT,
    updated_by      BIGINT,
    deleted_by      BIGINT,

    -- Constraints
    CONSTRAINT pk_app_user PRIMARY KEY (id),
    CONSTRAINT uq_app_user_username UNIQUE (username),
    CONSTRAINT uq_app_user_email UNIQUE (email),
    CONSTRAINT uq_app_user_public_id UNIQUE (public_id)
);


-- =========================================================================
-- Table: auth.login_history
-- Purpose: Immutable log of every login attempt — successful or failed.
--          Provides forensic data for security incident investigation.
--
-- Never updated or soft-deleted. Append-only by design. This is part of
-- the operational schema during MVP but will be mirrored to audit schema
-- when audit is implemented.
-- =========================================================================
CREATE TABLE auth.login_history (
    -- Surrogate primary key.
    id              BIGINT GENERATED ALWAYS AS IDENTITY,

    -- The user attempting to log in. FK to auth.app_user(id).
    -- NOT NULL: anonymous login failures are not tracked in MVP.
    user_id         BIGINT,

    -- Origin IP address. Stored as INET (not VARCHAR) for correct sorting,
    -- CIDR matching, and IP family (v4/v6) awareness.
    -- NULL = login attempt failed due to an invalid IP address.
    ip_address      INET,

    -- User-Agent header from the login request. Capped at 255 characters
    -- because most UAs fit within that; longer ones are truncated by the
    -- application layer before insert.
    user_agent      VARCHAR(255) NOT NULL,

    -- Outcome of the attempt. TRUE = credentials accepted. FALSE = rejected.
    -- Used for brute-force detection: COUNT(*) WHERE success = FALSE AND
    -- attempt_at > NOW() - INTERVAL '15 minutes' GROUP BY user_id.
    success         BOOLEAN NOT NULL,

    -- When the attempt occurred. Server-side timestamp (not client-supplied).
    attempt_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_login_history PRIMARY KEY (id),
    CONSTRAINT chk_login_history_ip_consistency CHECK (
        success IS FALSE OR ip_address IS NOT NULL
    ),
    CONSTRAINT chk_login_history_user_consistency CHECK (
        success IS FALSE OR user_id IS NOT NULL
        )
);


-- =========================================================================
-- Table: auth.app_user_profile
-- Purpose: One-to-one extension of app_user. Stores display-oriented fields
--          that are not needed for authentication queries.
--
-- Lifecycle: Created automatically when a user is created. Soft-deleted
-- when the user is soft-deleted. Profile deleted_at must mirror user
-- deleted_at — enforced at the application layer.
--
-- No created_at/created_by: profile creation is a side effect of user
-- creation, not an independent action. The user's created_at covers it.
-- =========================================================================
CREATE TABLE auth.app_user_profile (
    -- Surrogate primary key.
    id              BIGINT GENERATED ALWAYS AS IDENTITY,

    -- Owner of this profile. FK to auth.app_user(id).
    user_id         BIGINT NOT NULL,

    -- URL or key reference to profile picture in S3. Nullable because a user
    -- can exist without uploading a picture.
    profile_picture_url VARCHAR(128),

    -- Self-written bio or description. Free text, capped at 255 characters.
    user_description VARCHAR(255),

    -- Last modification timestamp.
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Soft-delete marker. Set when the corresponding app_user is soft-deleted.
    deleted_at      TIMESTAMPTZ,

    -- Who last modified this profile. FK to auth.app_user(id). NOT NULL
    -- because even the system-initiated profile creation is attributed to
    -- the user who triggered it (or a bootstrap admin).
    updated_by      BIGINT NOT NULL,

    CONSTRAINT pk_app_user_profile PRIMARY KEY (id)
);


-- =========================================================================
-- Table: auth.project_membership
-- Purpose: Which users belong to which projects. This is an entity, not a
--          pure join table — it has its own identity (id) because permissions
--          reference it via project_membership_permission.
--
-- Soft-delete: When a user is removed from a project, deleted_at is set.
-- The unique partial index below ensures the same user can be re-added
-- later (new row with deleted_at IS NULL) without colliding with the
-- soft-deleted row.
-- =========================================================================
CREATE TABLE auth.project_membership (
    -- Surrogate primary key. Referenced by project_membership_permission.
    id              BIGINT GENERATED ALWAYS AS IDENTITY,

    -- The user who is a member. FK to auth.app_user(id).
    user_id         BIGINT NOT NULL,

    -- The project they belong to. FK to projects.project(id).
    project_id      BIGINT NOT NULL,

    -- Record lifecycle timestamps.
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at      TIMESTAMPTZ, -- NULL = active membership

    -- Who performed the action. created_by is NOT NULL because membership
    -- is always granted by an existing user (Producer or Admin).
    -- deleted_by is NULL for active memberships, set when removed.
    created_by      BIGINT NOT NULL,
    updated_by      BIGINT NOT NULL,
    deleted_by      BIGINT,

    CONSTRAINT pk_project_membership PRIMARY KEY (id)
);


-- =========================================================================
-- Table: auth.project_membership_permission
-- Purpose: Granular permissions assigned to a specific user within a
--          specific project. Bridges project_membership to permissions.permission.
--
-- Without this table, permissions would be assigned at the user level
-- (global) or role level. This table enables per-project permission
-- assignment: User A can PUBLISH in Project X but only VIEW in Project Y.
-- =========================================================================
CREATE TABLE auth.project_membership_permission (
    -- Surrogate primary key.
    id              BIGINT GENERATED ALWAYS AS IDENTITY,

    -- The project membership this permission is scoped to.
    -- FK to auth.project_membership(id).
    user_project_id BIGINT NOT NULL,

    -- The specific permission granted. FK to permissions.permission(id).
    permission_id   BIGINT NOT NULL,

    -- Record lifecycle timestamps.
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at      TIMESTAMPTZ, -- NULL = active grant

    -- Who granted/revoked this permission.
    created_by      BIGINT NOT NULL,
    updated_by      BIGINT NOT NULL,
    deleted_by      BIGINT,

    CONSTRAINT pk_project_membership_permission PRIMARY KEY (id)
);


COMMIT TRANSACTION;