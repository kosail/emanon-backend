-- -------------------------------------------------------------
-- TRIGGERS
--
--
-- Designed by: kosail
-- With love, from Honduras.
--
-- Date: June 30, 2026
-- -------------------------------------------------------------


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
CREATE TRIGGER trg_app_user_update
    BEFORE UPDATE ON auth.app_user
    FOR EACH ROW
EXECUTE PROCEDURE trigger_update_timestamp();

CREATE TRIGGER trg_app_user_profile_update
    BEFORE UPDATE ON auth.app_user_profile
    FOR EACH ROW
EXECUTE PROCEDURE trigger_update_timestamp();

CREATE TRIGGER trg_project_membership_update
    BEFORE UPDATE ON project.project_membership
    FOR EACH ROW
EXECUTE PROCEDURE trigger_update_timestamp();

CREATE TRIGGER trg_project_membership_permission_update
    BEFORE UPDATE ON project.project_membership_permission
    FOR EACH ROW
EXECUTE PROCEDURE trigger_update_timestamp();

-- -----------------------------------
--        PERMISSIONS TRIGGERS
-- -----------------------------------

