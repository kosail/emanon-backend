package com.korealm.emanon.auth.internal.data.repositories;

import com.korealm.emanon.auth.internal.data.models.LoginHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface LoginHistoryRepository extends JpaRepository<LoginHistory, Long> {
}
