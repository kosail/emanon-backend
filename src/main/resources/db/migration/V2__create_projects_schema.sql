-- =========================================================================
-- Schema: projects
-- Purpose: Project lifecycle — creation, archival, and deletion.
--          Projects are the top-level organizational unit. Assets belong
--          to projects. Users belong to projects via memberships.
--
-- Lifecycle states:
--   ACTIVE   → Normal operation. Assets can be created and modified.
--              Memberships can be added/removed. Permissions can change.
--
--   ARCHIVED → Read-only. No new assets, no asset modifications, no
--              membership changes. Name and slug remain reserved. Fully
--              reversible: set status back to ACTIVE, NULL out archived_at.
--
--   DELETED  → Tombstone. The project row remains as proof the project
--              existed. All dependent data (memberships, membership
--              permissions, assets, asset versions) is permanently
--              destroyed. S3/MinIO objects are purged. Name and slug are
--              released for reuse by new projects (see partial indexes).
--
--              Partially reversible: the metadata row can be restored
--              (status → ACTIVE, deleted_at → NULL), but assets and
--              memberships cannot — they were physically destroyed.
--
-- Deletion flow (application-level, not SQL CASCADE):
--   1. User requests deletion → double confirmation + password.
--   2. Application (within a single transaction):
--      a. Hard-deletes all project_membership_permission rows.
--      b. Hard-deletes all project_membership rows.
--      c. Hard-deletes all asset_version rows.
--      d. Hard-deletes all asset rows.
--      e. Sets project.deleted_at = NOW(), status = 'DELETED', deleted_by.
--   3. After commit: async job deletes S3/MinIO objects for all purged
--      asset versions. If this step fails, objects remain but are
--      unreachable (the DB references are gone). Log and retry.
--
-- Why not ON DELETE CASCADE?
--   CASCADE makes accidental or malicious deletion a single-statement
--   catastrophe with no recovery path. The three-step application flow
--   (double confirm + password + transactional purge) ensures intentional
--   deletion with explicit audit trail on each purged entity.
--
--   Additionally, CASCADE would silently destroy data without the
--   application-level opportunity to record who deleted what, queue S3
--   cleanup jobs, or log forensics for incident response.
--
-- Why not soft-delete child rows?
--   Assets can be hundreds of MB to multiple GB. Retaining them for
--   soft-deleted projects wastes storage and incurs ongoing S3 costs.
--   The operational requirement to reclaim space overrides the general
--   soft-delete policy. The project row serves as a tombstone — proof
--   the project existed — while dependent data is purged.
--
-- Designed by: kosail
-- Date: June 30, 2026
-- =========================================================================

BEGIN TRANSACTION;

CREATE SCHEMA IF NOT EXISTS projects;


-- =========================================================================
-- Table: projects.project
-- Purpose: A game or software project (e.g., "Pet Society 2"). Top-level
--          container for all assets, versions, and memberships.
--
-- Tombstone semantics (DELETED state):
--   When a project is deleted, this row becomes a tombstone. It documents
--   the project's prior existence and who deleted it. All child tables
--   (memberships, assets, versions) are hard-deleted before the tombstone
--   is written. The project_id foreign key in auth.project_membership uses
--   ON DELETE RESTRICT — the database will reject a DELETE on this table
--   if memberships exist. The application must purge children first.
-- =========================================================================
CREATE TABLE projects.project (
    -- Surrogate primary key.
    id                    BIGINT GENERATED ALWAYS AS IDENTITY,

    -- Display name. Unique among non-deleted projects (see partial index).
    -- Maximum 128 characters: project names are titles, not descriptions.
    project_name          VARCHAR(128) NOT NULL,

    -- URL-friendly identifier derived from project_name. Lowercase,
    -- hyphenated, no special characters. Unique among non-deleted projects
    -- (see partial index).
    -- Example: "Pet Society 2" → "pet-society-2"
    slug                  VARCHAR(128) NOT NULL,

    -- Optional link to external resources (GitLab repository, Confluence
    -- page, shared drive). Max 512 to accommodate long URLs.
    project_external_url  VARCHAR(512),

    -- Optional icon shown in project list and header. Points to an S3 or
    -- MinIO object key/path. Max 512 for full qualified URLs or ARNs.
    project_icon_url      VARCHAR(512),

    -- Free-text description. TEXT type (no length limit) because project
    -- descriptions can be extensive and unpredictable.
    description           TEXT,

    -- Lifecycle state. CHECK constraint enforces valid values at the
    -- database level. No need of a lookup table because these values are
    -- not updated by users, and will likely never change.
    -- Application uses a Java enum that maps to these exact strings.
    --
    -- ACTIVE   : Normal operation. Assets modifiable. Memberships mutable.
    -- ARCHIVED : Read-only. Reversible. Name/slug reserved.
    -- DELETED  : Tombstone. Child data purged. Name/slug released.
    status                VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',

    -- Record lifecycle timestamps.
    -- created_at  : When the project was first created.
    -- updated_at  : Last modification to any non-lifecycle field.
    -- archived_at : When status was set to ARCHIVED. NULL if ACTIVE/DELETED.
    --                Indicates when the project became read-only.
    -- deleted_at  : When status was set to DELETED. NULL if ACTIVE/ARCHIVED.
    --                This is a tombstone timestamp, not a soft-delete
    --                marker. Dependent data is physically destroyed.
    created_at            TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    archived_at           TIMESTAMPTZ,
    deleted_at            TIMESTAMPTZ,

    -- Actor tracking. All FKs reference auth.app_user(id).
    -- created_by  : Who created the project. NOT NULL — every project has
    --               a creator (the first Admin/Producer).
    -- updated_by  : Who last modified the project. NOT NULL — always
    --               updated on any field change.
    -- archived_by : Who archived the project. NULL for ACTIVE/DELETED.
    -- deleted_by  : Who deleted the project. NULL for ACTIVE/ARCHIVED.
    --               Set during tombstone creation.
    created_by            BIGINT NOT NULL,
    updated_by            BIGINT NOT NULL,
    archived_by           BIGINT,
    deleted_by            BIGINT,

    -- Constraints
    CONSTRAINT pk_project PRIMARY KEY (id),
    CONSTRAINT chk_project_status CHECK (status IN ('ACTIVE', 'ARCHIVED', 'DELETED'))
);

COMMIT TRANSACTION;