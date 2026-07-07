package com.korealm.emanon.auth.internal.data.dto;

import jakarta.validation.constraints.NotBlank;
import org.jspecify.annotations.NullMarked;
import org.jspecify.annotations.Nullable;

@NullMarked
public record LoginResponseDto(
        @NotBlank String token,
        @Nullable String profilePictureUrl
) {}
