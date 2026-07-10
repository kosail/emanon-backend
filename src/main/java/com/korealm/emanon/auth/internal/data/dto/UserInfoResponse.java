package com.korealm.emanon.auth.internal.data.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Builder;
import org.jspecify.annotations.NullMarked;

@NullMarked @Builder
public record UserInfoResponse(
        @NotBlank String firstName,
        @NotBlank String lastName,
        @NotBlank String email
) {
}
