package com.korealm.emanon.auth.data.repositories;

import com.korealm.emanon.auth.data.models.ProjectMembershipPermission;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ProjectMembershipPermissionRepository extends JpaRepository<ProjectMembershipPermission, Long> {
}
