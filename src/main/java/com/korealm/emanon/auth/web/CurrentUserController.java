package com.korealm.emanon.auth.web;

import com.korealm.emanon.auth.internal.data.dto.*;
import com.korealm.emanon.auth.internal.security.AppUserDetailsAdapter;
import com.korealm.emanon.auth.internal.user.CurrentUserService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth/me")
@RequiredArgsConstructor
public class CurrentUserController {
    private final CurrentUserService service;

    // ME (CURRENT USER + PROFILE)
    @GetMapping
    public ResponseEntity<CurrentUserProfileResponse> currentUser(
            @AuthenticationPrincipal AppUserDetailsAdapter currentUser
    ) {
        final var res = service.getCurrentUser(currentUser.user());
        return ResponseEntity.ok(res);
    }

    // UPDATE PROFILE DESCRIPTION
    @PostMapping
    public ResponseEntity<Void> updateProfile(
            @Valid @NotNull UserProfileUpdateRequest req,
            @AuthenticationPrincipal AppUserDetailsAdapter currentUser
    ) {
        service.updateUserProfile(req, currentUser.user());
        return ResponseEntity.noContent().build();
    }

    // UPDATE USER PROFILE
    @PostMapping("/profile-picture/upload-url")
    public ResponseEntity<ProfilePictureUploadResponse> requestUpload(
            @Valid @NotNull ProfilePictureUploadRequest req,
            @AuthenticationPrincipal AppUserDetailsAdapter currentUser
    ) {
        final var response = service.requestUpload(
                req.contentType(), currentUser.user()
        );

        return ResponseEntity.ok(response);
    }

    @PutMapping("/profile-picture")
    public ResponseEntity<ProfilePictureConfirmResponse> confirmUpload(
            @Valid @RequestBody ProfilePictureConfirmRequest req,
            @AuthenticationPrincipal AppUserDetailsAdapter currentUser
    ) {
        final var response = service.confirmUpload(
                req.objectKey(), currentUser.user()
        );

        return ResponseEntity.ok(response);
    }


    // CHANGE PASSWORD (INCREMENTS TOKEN_VERSION)
    @PutMapping("/password")
    public ResponseEntity<UpdateCurrentUserPasswordResponse> updatePassword(
            @Valid @NotNull UpdateCurrentUserPasswordRequest req,
            @AuthenticationPrincipal AppUserDetailsAdapter currentUser
    ) {
        final var res = service.updateCurrentUserPassword(req, currentUser.user());
        return ResponseEntity.ok(res);
    }

    @DeleteMapping
    public ResponseEntity<Void> deleteSelfAccount(
            @AuthenticationPrincipal AppUserDetailsAdapter currentUser
    ) {
        service.selfDeleteAccount(currentUser.user());
        return ResponseEntity.noContent().build();
    }
}
