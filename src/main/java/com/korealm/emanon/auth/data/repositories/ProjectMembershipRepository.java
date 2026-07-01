package com.korealm.emanon.auth.data.repositories;

import com.korealm.emanon.auth.data.models.ProjectMembership;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ProjectMembershipRepository extends JpaRepository<ProjectMembership, Long> {
}
