-- =========================================================================
-- Schema: permissions
-- Purpose: Defines the set of all possible permissions in the system using
--          an action/target decomposition. Permissions are seeded during
--          deployment and rarely change at runtime.
--
-- Design rationale: Separating action (CREATE, READ, UPDATE, DELETE,
-- PUBLISH, etc.) from target (PROJECT, ASSET, USER, etc.) lets the
-- permission matrix grow without schema changes. Adding a new action or
-- target is a row insert, not a DDL migration.
--
-- Designed by: kosail
-- Date: June 29, 2026
-- =========================================================================

BEGIN TRANSACTION;

CREATE SCHEMA permissions;

-- =========================================================================
-- Table: permissions.action_type
-- Purpose: Enumeration of actions a user can perform. Example values:
--          CREATE, READ, UPDATE, DELETE, PUBLISH, DOWNLOAD, UPLOAD.
--
-- Audit columns omitted (no created_by/updated_by) because this table is
-- seeded via migration scripts, not application runtime. There is no
-- "user performing the action" during deployment. created_at/updated_at
-- are kept for migration tracking.
-- =========================================================================
CREATE TABLE permissions.action_type (
    -- SMALLINT is sufficient: we expect at most ~15 action types. The
    -- 32,767 limit of SMALLINT will never be reached by this table.
    id              SMALLINT GENERATED ALWAYS AS IDENTITY,

    -- Human-readable action name. Used in authorization annotations and
    -- permission checks (e.g., @PreAuthorize("hasPermission('PUBLISH')")).
    action_name     VARCHAR(64) NOT NULL,

    -- Record lifecycle timestamps. Set during migration execution.
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at      TIMESTAMPTZ, -- Reserved; unlikely to be used for seed data

    CONSTRAINT pk_action_type PRIMARY KEY (id),
    CONSTRAINT uq_action_name UNIQUE (action_name)
);


-- =========================================================================
-- Table: permissions.action_target
-- Purpose: Enumeration of resource types an action can apply to. Example
--          values: PROJECT, ASSET, ASSET_VERSION, USER, MEMBERSHIP.
--
-- Same rationale as action_type: seed data, not runtime data. Audit columns
-- omitted.
-- =========================================================================
CREATE TABLE permissions.action_target (
    -- SMALLINT for the same reason as action_type: bounded, small dataset.
    id              SMALLINT GENERATED ALWAYS AS IDENTITY,

    -- Human-readable target name. Matches the resource type string used in
    -- authorization logic.
    action_target   VARCHAR(64) NOT NULL,

    -- Record lifecycle timestamps.
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at      TIMESTAMPTZ,

    CONSTRAINT pk_action_target PRIMARY KEY (id),
    CONSTRAINT uq_action_target UNIQUE (action_target)
);


-- =========================================================================
-- Table: permissions.permission
-- Purpose: The Cartesian product of action_type × action_target that
--          defines every possible permission in the system.
--
-- Example rows:
--   (CREATE, PROJECT)       → "can create a project"
--   (PUBLISH, ASSET)        → "can publish an asset version"
--   (DOWNLOAD, ASSET)       → "can download asset files"
--   (MANAGE, MEMBERSHIP)    → "can add/remove users from a project"
--
-- This table is the junction of action_type and action_target. It is
-- referenced by project_membership_permission to grant specific
-- permissions to specific users within specific projects.
--
-- Audit columns omitted for the same reason as action_type/action_target:
-- seed data populated during deployment, not by application users.
-- =========================================================================
CREATE TABLE permissions.permission (
    -- BIGINT because the number of rows is the Cartesian product of
    -- action_type × action_target. If we have 10 actions and 10 targets,
    -- that's 100 rows. Still small, but BIGINT is the project default for
    -- entity table PKs and using it here maintains consistency.
    id                BIGINT GENERATED ALWAYS AS IDENTITY,

    -- Which action. FK to permissions.action_type(id).
    action_type_id    SMALLINT NOT NULL,

    -- What resource type the action applies to. FK to permissions.action_target(id).
    action_target_id  SMALLINT NOT NULL,

    -- Record lifecycle timestamps.
    created_at        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at        TIMESTAMPTZ,

    CONSTRAINT pk_permission PRIMARY KEY (id),
    -- Each (action, target) pair appears at most once.
    CONSTRAINT uq_permission_action_type_action_target UNIQUE (action_type_id, action_target_id)
);


-- =========================================================================
-- INDEXES
-- =========================================================================

-- No additional indexes on action_type or action_target: they are small
-- lookup tables (≤ 50 rows each). The PK indexes on id and the UNIQUE
-- constraints on name are sufficient for all query patterns.
--
-- No additional indexes on permission: the unique constraint on
-- (action_type_id, action_target_id) already serves as a composite index,
-- and the PK index covers id lookups from project_membership_permission.

COMMIT TRANSACTION;