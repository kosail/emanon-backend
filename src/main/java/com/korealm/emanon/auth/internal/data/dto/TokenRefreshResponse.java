package com.korealm.emanon.auth.internal.data.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Builder;
import org.jspecify.annotations.NullMarked;

@NullMarked @Builder
public record TokenRefreshResponse(
        @NotNull String accessToken,
        @NotNull String refreshToken
) { }
