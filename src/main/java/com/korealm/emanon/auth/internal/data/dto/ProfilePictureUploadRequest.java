package com.korealm.emanon.auth.internal.data.dto;

import jakarta.validation.constraints.NotBlank;
import org.jspecify.annotations.NullMarked;

@NullMarked
public record ProfilePictureUploadRequest(
        @NotBlank String contentType // "image/png", "image/jpeg", etc.
) { }