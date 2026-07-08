package com.korealm.emanon.auth.internal.data.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.jspecify.annotations.NullMarked;

@NullMarked
public record CreateUserRequest(
        @NotBlank String firstName,
        @NotBlank String lastName,
        @NotBlank String username,
        @NotBlank String password,
        @NotNull @Email String email
) {}
