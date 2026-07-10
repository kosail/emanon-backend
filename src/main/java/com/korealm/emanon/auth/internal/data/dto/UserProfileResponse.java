package com.korealm.emanon.auth.internal.data.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Builder;
import org.jspecify.annotations.NullMarked;
import org.jspecify.annotations.Nullable;

@NullMarked @Builder
public record UserProfileResponse(
        @NotBlank String firstName,
        @NotBlank String lastName,
        @NotBlank String email,
        @Nullable String description,
        @Nullable String profilePictureUrl
) {
}
