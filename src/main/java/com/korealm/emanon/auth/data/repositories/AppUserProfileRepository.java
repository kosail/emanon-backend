package com.korealm.emanon.auth.data.repositories;

import com.korealm.emanon.auth.data.models.AppUserProfile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AppUserProfileRepository extends JpaRepository<AppUserProfile, Long> {
}
