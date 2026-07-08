package com.korealm.emanon.auth.internal.data.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Builder;
import org.jspecify.annotations.NullMarked;
import org.jspecify.annotations.Nullable;

import java.util.UUID;

@NullMarked @Builder
public record CreateUserResponse(
        @NotNull UUID userId, // This is the public user ID
        @NotBlank String username,
        @NotBlank String firstName,
        @NotBlank String lastName,
        @NotNull @Email String email
) {}
