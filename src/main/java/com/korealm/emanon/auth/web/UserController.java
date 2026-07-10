package com.korealm.emanon.auth.web;

import com.korealm.emanon.auth.internal.data.dto.UserInfoResponse;
import com.korealm.emanon.auth.internal.data.dto.UserInfoUpdateRequest;
import com.korealm.emanon.auth.internal.data.dto.UserProfileResponse;
import com.korealm.emanon.auth.internal.data.models.AppUser;
import com.korealm.emanon.auth.internal.user.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/auth/user")
@RequiredArgsConstructor
public class UserController {
    private final UserService service;

    // LIST ALL USERS
    @GetMapping("/all")
    public ResponseEntity<List<UserInfoResponse>> getAll() {
        final var res = service.getAll();
        return ResponseEntity.ok(res);
    }

    @GetMapping("/active")
    public ResponseEntity<List<UserInfoResponse>> getAllActive() {
        final var res = service.getAllActive();
        return ResponseEntity.ok(res);
    }

    // GET A SINGLE USER
    @GetMapping("/{userPublicId}")
    public ResponseEntity<UserProfileResponse> getProfile(
            @PathVariable UUID userPublicId
    ) {
        final var res = service.getProfile(userPublicId);
        return ResponseEntity.ok(res);
    }

    // --------------------------------------------------------------------------------------------------------
    // TODO: These functionality cannot be implemented because the MVP does not have such concept as user roles
    // No admins = No one have the permission to alter another user's information
    // I will work on this later on.
    // --------------------------------------------------------------------------------------------------------

    // UPDATE ANOTHER USER INFORMATION
    @PutMapping("/update/{userPublicId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> updateUserInformation(
            @PathVariable UUID userPublicId,
            @RequestBody UserInfoUpdateRequest req,
            @AuthenticationPrincipal AppUser adminUser
    ) {
        service.updateUserInformation(userPublicId, req, adminUser);
        return ResponseEntity.noContent().build();
    }

    // SOFT DELETE ANOTHER USER
    @DeleteMapping("/delete/{userPublicId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteUser(
            @PathVariable UUID userPublicId,
            @AuthenticationPrincipal AppUser adminUser
    ) {
        service.deleteUserAccount(userPublicId, adminUser);
        return ResponseEntity.noContent().build();
    }


    // RESTORE A SOFT DELETED USER
    @PutMapping("/restore/{userPublicId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> restoreUser(
            @PathVariable UUID userPublicId,
            @AuthenticationPrincipal AppUser adminUser
    ) {
        service.restoreUserAccount(userPublicId, adminUser);
        return ResponseEntity.noContent().build();
    }
}
