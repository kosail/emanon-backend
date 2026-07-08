package com.korealm.emanon.auth.internal.data.dto;

import jakarta.validation.constraints.NotBlank;
import org.jspecify.annotations.NullMarked;

@NullMarked
public record LoginRequest(
        @NotBlank String username,
        @NotBlank String password
) {}
