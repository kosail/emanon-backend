package com.korealm.emanon.auth.internal.data.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Builder;
import org.jspecify.annotations.NullMarked;

import java.time.OffsetDateTime;

@NullMarked @Builder
public record ProfilePictureUploadResponse(
    @NotBlank String uploadUrl,
    @NotBlank String objectKey,
    @NotNull OffsetDateTime expiresAt
) {
}
