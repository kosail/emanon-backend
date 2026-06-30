-- =========================================================================
-- AUTH INDEXES
-- =========================================================================

-- Enforces "one active membership per user per project".
-- Partial index (WHERE deleted_at IS NULL) allows soft-deleted rows to
-- coexist. When a user is re-added to a project, a new row is inserted
-- and the old soft-deleted row does not violate uniqueness.
CREATE UNIQUE INDEX idx_project_membership_user_project
    ON auth.project_membership(user_id, project_id)
    WHERE deleted_at IS NULL;

-- Enforces "a permission cannot be granted twice to the same membership".
-- Same partial-index pattern as above.
CREATE UNIQUE INDEX idx_project_membership_permission_user_project
    ON auth.project_membership_permission(user_project_id, permission_id)
    WHERE deleted_at IS NULL;

-- Supports reverse lookup: "show all memberships that have permission X".
-- Used when permission X is revoked globally — find all grants to remove.
CREATE INDEX idx_project_membership_permission_permission
    ON auth.project_membership_permission(permission_id)
    WHERE deleted_at IS NULL;



-- =========================================================================
-- PROJECT INDEXES
--
-- Design notes:
-- - Partial indexes with WHERE deleted_at IS NULL are used for uniqueness
--   constraints because tombstone rows (deleted projects) release their
--   name and slug for reuse. The partial index excludes tombstone rows,
--   so a new project can reuse a name/slug that belonged to a deleted one.
-- =========================================================================

-- Uniqueness index for project_name across non-deleted projects.
-- Tombstones are excluded: a deleted project releases its name.
CREATE UNIQUE INDEX uq_project_name
    ON projects.project (project_name)
    WHERE deleted_at IS NULL;

-- Uniqueness index for slug across non-deleted projects.
-- Same tombstone exclusion pattern as project_name.
CREATE UNIQUE INDEX uq_project_slug
    ON projects.project (slug)
    WHERE deleted_at IS NULL;

-- Supports "list all archived projects" queries.
-- Covers only archived rows (NULL values excluded by WHERE).
CREATE INDEX idx_project_archived_at
    ON projects.project (archived_at)
    WHERE archived_at IS NOT NULL;

-- Supports filtered queries: "show me all ACTIVE projects" or
-- "show me all ARCHIVED projects". Excludes tombstone rows
-- because most operational queries filter out deleted projects.
CREATE INDEX idx_project_status
    ON projects.project (status)
    WHERE deleted_at IS NULL;