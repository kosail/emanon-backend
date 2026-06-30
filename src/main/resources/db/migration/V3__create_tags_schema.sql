-- =========================================================================
-- Schema: tags
-- Purpose: Categorization system for assets. Tags can be global (visible
--          across all projects) or scoped to a single project.
--
-- Tag scoping:
--   project_id = NULL    → Global tag. Visible and usable in all projects.
--   project_id = NOT NULL → Project-scoped tag. Only usable within that
--                            specific project. Prevents tag namespace
--                            pollution between projects (e.g., one project's
--                            "UI" tag does not clutter another project's
--                            filtering UI).
--
-- Tag creation:
--   Tags are created at runtime by users with the MANAGE_TAGS permission
--   (defined in permissions schema). They are not seeded during deployment
--   because the set of useful tags varies per project and per studio.
--
-- Deletion: Soft delete (deleted_at). When a tag is soft-deleted, existing
--   assets tagged with it retain the association; the tag simply stops
--   appearing in creation/assignment UIs. Hard-deleting a tag while assets
--   reference it would break referential integrity (once a junction table
--   for asset-tag is added).
--
-- Uniqueness rules:
--   - Global tag names are unique across all global tags.
--   - Project-scoped tag names are unique within their project.
--   - A global tag "UI" and a project-scoped "UI" can coexist (different
--     scopes). See indexes for enforcement.
--
-- Designed by: kosail
-- Date: June 30, 2026
-- =========================================================================

BEGIN TRANSACTION;

CREATE SCHEMA IF NOT EXISTS tags;

-- =========================================================================
-- Table: tags.tag
-- Purpose: A single tag entity. Can be assigned to assets for filtering,
--          searching, and organization.
--
-- Scope: Controlled by project_id. NULL = global, NOT NULL = project-scoped.
--         A tag cannot change scope after creation (no project_id update
--         allowed in application logic) because assets already assigned to
--         it would inherit the new scope, which is semantically invalid.
-- =========================================================================
CREATE TABLE tags.tag (
    -- Surrogate primary key. No business meaning.
    id              BIGINT GENERATED ALWAYS AS IDENTITY,

    -- Name of the tag as displayed in the UI (e.g., "UI", "Character",
    -- "Environment", "Animation"). Case-sensitive. Maximum 128 characters.
    -- Uniqueness depends on scope (see indexes).
    tag_name        VARCHAR(128) NOT NULL,

    -- Scope of the tag. FK to projects.project(id).
    -- NULL  = Global tag, visible and usable in all projects.
    -- NOT NULL = Scoped to a specific project. Only usable within that project.
    -- Cannot change after creation.
    project_id      BIGINT,

    -- Record lifecycle timestamps.
    -- updated_at is maintained by trigger (trg_tags_tag_update in V8).
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at      TIMESTAMPTZ, -- NULL = active tag

    -- Actor tracking. FK to auth.app_user(id).
    -- created_by is NOT NULL: tags are always created by an authenticated user.
    created_by      BIGINT NOT NULL,
    updated_by      BIGINT NOT NULL,
    deleted_by      BIGINT,

    -- Constraints
    CONSTRAINT pk_tag PRIMARY KEY (id)
);

COMMIT TRANSACTION;
