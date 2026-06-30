-- -----------------------------------
--             FUNCTIONS
-- -----------------------------------
CREATE OR REPLACE FUNCTION trigger_update_timestamp()
    RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;



-- -----------------------------------
--         AUTH TRIGGERS
-- -----------------------------------
CREATE TRIGGER trg_auth_app_user_update
    BEFORE UPDATE ON auth.app_user
    FOR EACH ROW
EXECUTE PROCEDURE trigger_update_timestamp();

CREATE TRIGGER trg_auth_app_user_profile_update
    BEFORE UPDATE ON auth.app_user_profile
    FOR EACH ROW
EXECUTE PROCEDURE trigger_update_timestamp();

CREATE TRIGGER trg_auth_project_membership_update
    BEFORE UPDATE ON auth.project_membership
    FOR EACH ROW
EXECUTE PROCEDURE trigger_update_timestamp();

CREATE TRIGGER trg_auth_project_membership_permission_update
    BEFORE UPDATE ON auth.project_membership_permission
    FOR EACH ROW
EXECUTE PROCEDURE trigger_update_timestamp();


-- -----------------------------------
--        PROJECTS TRIGGERS
-- -----------------------------------
CREATE TRIGGER trg_project_project_update
    BEFORE UPDATE ON projects.project
    FOR EACH ROW
EXECUTE PROCEDURE trigger_update_timestamp();


-- -----------------------------------
--        TAGS TRIGGERS
-- -----------------------------------
CREATE TRIGGER trg_tags_tag_update
    BEFORE UPDATE ON tags.tag
    FOR EACH ROW
EXECUTE PROCEDURE trigger_update_timestamp();

-- -----------------------------------
--        ASSETS TRIGGERS
-- -----------------------------------
CREATE TRIGGER trg_assets_asset_update
    BEFORE UPDATE ON assets.asset
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_update_timestamp();

CREATE TRIGGER trg_assets_asset_version_update
    BEFORE UPDATE ON assets.asset_version
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_update_timestamp();

-- -----------------------------------
--        PERMISSIONS TRIGGERS
-- -----------------------------------
CREATE TRIGGER trg_permissions_action_type_update
    BEFORE UPDATE ON permissions.action_type
    FOR EACH ROW
EXECUTE PROCEDURE trigger_update_timestamp();

CREATE TRIGGER trg_permissions_action_target_update
    BEFORE UPDATE ON permissions.action_target
    FOR EACH ROW
EXECUTE PROCEDURE trigger_update_timestamp();

CREATE TRIGGER trg_permissions_permission_update
    BEFORE UPDATE ON permissions.permission
    FOR EACH ROW
EXECUTE PROCEDURE trigger_update_timestamp();