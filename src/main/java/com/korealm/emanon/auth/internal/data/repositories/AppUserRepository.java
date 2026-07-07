package com.korealm.emanon.auth.internal.data.repositories;

import com.korealm.emanon.auth.internal.data.models.AppUser;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AppUserRepository extends JpaRepository<AppUser, java.lang.Long> {
    Optional<AppUser> findByIdAndDeletedAtIsNull(Long userId);
    Optional<AppUser> findByUsername(String username);
}
