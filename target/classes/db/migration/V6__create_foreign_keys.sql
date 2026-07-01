-- =========================================================================
--  AUTH FOREIGN KEYS
-- =========================================================================

-- app_user self-referencing audit FKs.
-- These point back to the user table so we can track which user created,
-- updated, or deleted another user. NULL permitted for bootstrap.
ALTER TABLE auth.app_user
    ADD CONSTRAINT fk_auth_app_user_created_by
        FOREIGN KEY (created_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;

ALTER TABLE auth.app_user
    ADD CONSTRAINT fk_auth_app_user_updated_by
        FOREIGN KEY (updated_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;

ALTER TABLE auth.app_user
    ADD CONSTRAINT fk_auth_app_user_deleted_by
        FOREIGN KEY (deleted_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;


-- login_history -> app_user
ALTER TABLE auth.login_history
    ADD CONSTRAINT fk_auth_login_history_user_id
        FOREIGN KEY (user_id)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;


-- app_user_profile → app_user
ALTER TABLE auth.app_user_profile
    ADD CONSTRAINT fk_auth_app_user_profile_user
        FOREIGN KEY (user_id)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;

ALTER TABLE auth.app_user_profile
    ADD CONSTRAINT fk_auth_app_user_profile_updated_by
        FOREIGN KEY (updated_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;


-- project_membership FKs
ALTER TABLE auth.project_membership
    ADD CONSTRAINT fk_auth_project_membership_user
        FOREIGN KEY (user_id)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;

ALTER TABLE auth.project_membership
    ADD CONSTRAINT fk_auth_project_membership_project
        FOREIGN KEY (project_id)
            REFERENCES projects.project(id)
            ON DELETE RESTRICT;

ALTER TABLE auth.project_membership
    ADD CONSTRAINT fk_auth_project_membership_created_by
        FOREIGN KEY (created_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;

ALTER TABLE auth.project_membership
    ADD CONSTRAINT fk_auth_project_membership_updated_by
        FOREIGN KEY (updated_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;

ALTER TABLE auth.project_membership
    ADD CONSTRAINT fk_auth_project_membership_deleted_by
        FOREIGN KEY (deleted_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;


-- project_membership_permission FKs
ALTER TABLE auth.project_membership_permission
    ADD CONSTRAINT fk_auth_project_membership_permission_user_project
        FOREIGN KEY (user_project_id)
            REFERENCES auth.project_membership(id)
            ON DELETE RESTRICT;

ALTER TABLE auth.project_membership_permission
    ADD CONSTRAINT fk_auth_project_membership_permission_permission
        FOREIGN KEY (permission_id)
            REFERENCES permissions.permission(id)
            ON DELETE RESTRICT;

ALTER TABLE auth.project_membership_permission
    ADD CONSTRAINT fk_auth_project_membership_permission_created_by
        FOREIGN KEY (created_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;

ALTER TABLE auth.project_membership_permission
    ADD CONSTRAINT fk_auth_project_membership_permission_updated_by
        FOREIGN KEY (updated_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;

ALTER TABLE auth.project_membership_permission
    ADD CONSTRAINT fk_auth_project_membership_permission_deleted_by
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
    ADD CONSTRAINT fk_projects_project_created_by
        FOREIGN KEY (created_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;

ALTER TABLE projects.project
    ADD CONSTRAINT fk_projects_project_updated_by
        FOREIGN KEY (updated_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;

ALTER TABLE projects.project
    ADD CONSTRAINT fk_projects_project_archived_by
        FOREIGN KEY (archived_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;

ALTER TABLE projects.project
    ADD CONSTRAINT fk_projects_project_deleted_by
        FOREIGN KEY (deleted_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;



-- =========================================================================
-- PERMISSIONS FOREIGN KEYS
-- =========================================================================

-- permission → action_type
ALTER TABLE permissions.permission
    ADD CONSTRAINT fk_permissions_permission_action_type
        FOREIGN KEY (action_type_id)
            REFERENCES permissions.action_type(id)
            ON DELETE RESTRICT;

-- permission → action_target
ALTER TABLE permissions.permission
    ADD CONSTRAINT fk_permissions_permission_action_target
        FOREIGN KEY (action_target_id)
            REFERENCES permissions.action_target(id)
            ON DELETE RESTRICT;


-- =========================================================================
-- TAGS FOREIGN KEYS
-- =========================================================================
ALTER TABLE tags.tag
    ADD CONSTRAINT fk_tags_tag_project
        FOREIGN KEY (project_id)
            REFERENCES projects.project(id)
            ON DELETE RESTRICT;
ALTER TABLE tags.tag
    ADD CONSTRAINT fk_tags_tag_created_by
        FOREIGN KEY (created_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;
ALTER TABLE tags.tag
    ADD CONSTRAINT fk_tags_tag_updated_by
        FOREIGN KEY (updated_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;
ALTER TABLE tags.tag
    ADD CONSTRAINT fk_tags_tag_deleted_by
        FOREIGN KEY (deleted_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;


-- =========================================================================
-- ASSETS FOREIGN KEYS
-- =========================================================================

ALTER TABLE assets.asset
    ADD CONSTRAINT fk_assets_asset_project_id
        FOREIGN KEY (project_id)
            REFERENCES projects.project(id)
            ON DELETE RESTRICT;

ALTER TABLE assets.asset
    ADD CONSTRAINT fk_assets_asset_created_by
        FOREIGN KEY (created_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;

ALTER TABLE assets.asset
    ADD CONSTRAINT fk_assets_asset_updated_by
        FOREIGN KEY (updated_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;

ALTER TABLE assets.asset
    ADD CONSTRAINT fk_assets_asset_deleted_by
        FOREIGN KEY (deleted_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;



ALTER TABLE assets.asset_version
    ADD CONSTRAINT fk_assets_asset_version_asset
        FOREIGN KEY (asset_id)
            REFERENCES assets.asset(id)
            ON DELETE RESTRICT;

ALTER TABLE assets.asset_version
    ADD CONSTRAINT fk_asset_asset_version_file_id
        FOREIGN KEY (file_id)
            REFERENCES assets.asset_file(id)
            ON DELETE RESTRICT;
            
ALTER TABLE assets.asset_version
    ADD CONSTRAINT fk_assets_asset_version_created_by
        FOREIGN KEY (created_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;

ALTER TABLE assets.asset_version
    ADD CONSTRAINT fk_assets_asset_version_updated_by
        FOREIGN KEY (updated_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;

ALTER TABLE assets.asset_version
    ADD CONSTRAINT fk_assets_asset_version_deleted_by
        FOREIGN KEY (deleted_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;


            
ALTER TABLE assets.asset_file
    ADD CONSTRAINT fk_assets_asset_file_version 
        FOREIGN KEY (asset_version_id)
            REFERENCES assets.asset_version(id)
            ON DELETE RESTRICT;


ALTER TABLE assets.asset_file
    ADD CONSTRAINT fk_assets_asset_file_uploaded_by
        FOREIGN KEY (uploaded_by)
            REFERENCES auth.app_user(id)
            ON DELETE RESTRICT;