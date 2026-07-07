package com.korealm.emanon.auth.internal.data.repositories;

import com.korealm.emanon.auth.internal.data.models.AppUserProfile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AppUserProfileRepository extends JpaRepository<AppUserProfile, Long> {
    Optional<AppUserProfile> findByUserId(Long userId);
}
