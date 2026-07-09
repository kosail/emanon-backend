package com.korealm.emanon.auth.internal.data.dto;

public record UserProfileUpdateRequest(
        String firstName,
        String lastName,
        String username,
        String email,
        String description
) {
}
