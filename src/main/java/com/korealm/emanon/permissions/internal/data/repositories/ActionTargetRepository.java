package com.korealm.emanon.permissions.internal.data.repositories;

import com.korealm.emanon.permissions.internal.data.models.ActionTarget;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ActionTargetRepository extends JpaRepository<ActionTarget, Long> {
}
