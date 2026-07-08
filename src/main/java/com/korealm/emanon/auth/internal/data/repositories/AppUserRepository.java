package com.korealm.emanon.auth.internal.data.repositories;

import com.korealm.emanon.auth.internal.data.models.AppUser;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AppUserRepository extends JpaRepository<AppUser, java.lang.Long> {
    Optional<AppUser> findByIdAndDeletedAtIsNull(@NotNull Long userId);
    Optional<AppUser> findByUsername(@NotBlank String username);
    Optional<AppUser> findByUsernameOrEmail(@NotBlank String username, @NotNull @Email String email);
}
