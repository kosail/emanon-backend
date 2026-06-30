-- =========================================================================
--  AUTH FOREIGN KEYS
-- =========================================================================

-- app_user self-referencing audit FKs.
-- These point back to the user table so we can track which user created,
-- updated, or deleted another user. NULL permitted for bootstrap.
ALTER TABLE auth.app_user
    ADD CONSTRAINT fk_app_user_created_by
        FOREIGN KEY (created_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;

ALTER TABLE auth.app_user
    ADD CONSTRAINT fk_app_user_updated_by
        FOREIGN KEY (updated_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;

ALTER TABLE auth.app_user
    ADD CONSTRAINT fk_app_user_deleted_by
        FOREIGN KEY (deleted_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;


-- app_user_profile → app_user
ALTER TABLE auth.app_user_profile
    ADD CONSTRAINT fk_app_user_profile_user
        FOREIGN KEY (user_id)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;

ALTER TABLE auth.app_user_profile
    ADD CONSTRAINT fk_app_user_profile_updated_by
        FOREIGN KEY (updated_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;


-- project_membership FKs
ALTER TABLE auth.project_membership
    ADD CONSTRAINT fk_project_membership_user
        FOREIGN KEY (user_id)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;

ALTER TABLE auth.project_membership
    ADD CONSTRAINT fk_project_membership_project
        FOREIGN KEY (project_id)
            REFERENCES projects.project(id)
            ON DELETE RESTRICT;

ALTER TABLE auth.project_membership
    ADD CONSTRAINT fk_project_membership_created_by
        FOREIGN KEY (created_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;

ALTER TABLE auth.project_membership
    ADD CONSTRAINT fk_project_membership_updated_by
        FOREIGN KEY (updated_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;

ALTER TABLE auth.project_membership
    ADD CONSTRAINT fk_project_membership_deleted_by
        FOREIGN KEY (deleted_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;


-- project_membership_permission FKs
ALTER TABLE auth.project_membership_permission
    ADD CONSTRAINT fk_project_membership_permission_user_project
        FOREIGN KEY (user_project_id)
            REFERENCES auth.project_membership(id)
            ON DELETE RESTRICT;

ALTER TABLE auth.project_membership_permission
    ADD CONSTRAINT fk_project_membership_permission_permission
        FOREIGN KEY (permission_id)
            REFERENCES permissions.permission(id)
            ON DELETE RESTRICT;

ALTER TABLE auth.project_membership_permission
    ADD CONSTRAINT fk_project_membership_permission_created_by
        FOREIGN KEY (created_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;

ALTER TABLE auth.project_membership_permission
    ADD CONSTRAINT fk_project_membership_permission_updated_by
        FOREIGN KEY (updated_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;

ALTER TABLE auth.project_membership_permission
    ADD CONSTRAINT fk_project_membership_permission_deleted_by
        FOREIGN KEY (deleted_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;



-- =========================================================================
-- PROJECTS FOREIGN KEYS
--
-- All audit-by columns point to auth.app_user(id) with ON DELETE RESTRICT.
-- This prevents hard-deleting a user who has created/archived/deleted
-- projects. The user must be soft-deleted instead, preserving the
-- referential integrity of the audit trail.
-- =========================================================================

ALTER TABLE projects.project
    ADD CONSTRAINT fk_project_created_by
        FOREIGN KEY (created_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;

ALTER TABLE projects.project
    ADD CONSTRAINT fk_project_updated_by
        FOREIGN KEY (updated_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;

ALTER TABLE projects.project
    ADD CONSTRAINT fk_project_archived_by
        FOREIGN KEY (archived_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;

ALTER TABLE projects.project
    ADD CONSTRAINT fk_project_deleted_by
        FOREIGN KEY (deleted_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;



-- =========================================================================
-- PERMISSIONS FOREIGN KEYS
-- =========================================================================

-- permission → action_type
ALTER TABLE permissions.permission
    ADD CONSTRAINT fk_permission_action_type
        FOREIGN KEY (action_type_id)
            REFERENCES permissions.action_type(id)
            ON DELETE RESTRICT;

-- permission → action_target
ALTER TABLE permissions.permission
    ADD CONSTRAINT fk_permission_action_target
        FOREIGN KEY (action_target_id)
            REFERENCES permissions.action_target(id)
            ON DELETE RESTRICT;
