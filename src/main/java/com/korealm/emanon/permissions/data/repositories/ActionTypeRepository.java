package com.korealm.emanon.permissions.data.repositories;

import com.korealm.emanon.permissions.data.models.ActionType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ActionTypeRepository extends JpaRepository<ActionType, Long> {
}
