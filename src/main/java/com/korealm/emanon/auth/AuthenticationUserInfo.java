package com.korealm.emanon.auth;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Builder;
import org.jspecify.annotations.NullMarked;

import java.util.UUID;

@NullMarked @Builder
public record AuthenticationUserInfo(
        @NotNull UUID publicId,
        @NotBlank String username,
        @NotBlank Integer tokenVersion
) {
}
