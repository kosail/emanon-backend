package com.korealm.emanon.auth.internal.data.repositories;

import com.korealm.emanon.auth.internal.data.models.AppUser;
import jakarta.annotation.Nullable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AppUserRepository extends JpaRepository<AppUser, java.lang.Long> {
    @Nullable
    Optional<AppUser> findByIdAndDeletedAtIsNull(Long userId);
}
