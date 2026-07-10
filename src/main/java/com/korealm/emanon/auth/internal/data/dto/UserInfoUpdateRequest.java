package com.korealm.emanon.auth.internal.data.dto;


import jakarta.validation.constraints.NotNull;

public record UserInfoUpdateRequest(
        String firstName,
        String lastName,
        String username,
        String description,
        @NotNull boolean removeProfilePicture
) {
}
