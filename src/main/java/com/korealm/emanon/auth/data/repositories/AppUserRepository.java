package com.korealm.emanon.auth.data.repositories;

import com.korealm.emanon.auth.data.models.AppUser;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AppUserRepository extends JpaRepository<AppUser, Long> {
}
