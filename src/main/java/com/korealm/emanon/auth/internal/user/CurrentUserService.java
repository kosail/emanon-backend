package com.korealm.emanon.auth.internal.user;

import com.korealm.emanon.auth.AuthenticationUserInfo;
import com.korealm.emanon.auth.internal.data.dto.*;
import com.korealm.emanon.auth.internal.data.models.AppUser;
import com.korealm.emanon.auth.internal.data.repositories.AppUserProfileRepository;
import com.korealm.emanon.auth.internal.data.repositories.AppUserRepository;
import com.korealm.emanon.security.JwtService;
import com.korealm.emanon.shared.StorageService;
import com.korealm.emanon.shared.exceptions.UnauthorizedException;
import lombok.RequiredArgsConstructor;
import org.jspecify.annotations.NullMarked;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.UUID;

@NullMarked
@Service
@RequiredArgsConstructor
public class CurrentUserService {
    private final AppUserRepository userRepo;
    private final AppUserProfileRepository profileRepo;

    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final StorageService storage;

    @Value("${cdn.storage.profile_storage_path}") private String storagePath;
    @Value("${cdn.storage.presigned_url_expiration_seconds}") private int presignedUrlExpirationSeconds;


    @Transactional(readOnly = true)
    public CurrentUserProfileResponse getCurrentUser(final AppUser user) {
        final var profile = profileRepo.findByUserId(user.getId())
                .orElseThrow(() -> new IllegalStateException("User profile not found"));

        final var objectKey = profile.getProfilePictureUrl();
        final var profilePictureUrl = objectKey == null || objectKey.isBlank()
                ? null : storage.generateDownloadUrl(objectKey);

        return CurrentUserProfileResponse.builder()
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .username(user.getUsername())
                .description(profile.getUserDescription())
                .profilePictureUrl(profilePictureUrl)
                .build();
    }

    @Transactional
    public void updateUserProfile(
            final UserProfileUpdateRequest req,
            final AppUser user
    ) {
        if (req.description() != null) {
            final var profile = profileRepo.findByUserId(user.getId())
                    .orElseThrow(() -> new IllegalStateException("User profile not found"));

            profile.setUserDescription(req.description());
            profileRepo.save(profile);
        }

        if (req.firstName() != null) user.setFirstName(req.firstName());
        if (req.lastName() != null) user.setLastName(req.lastName());
        if (req.username() != null) user.setUsername(req.username());
        if (req.email() != null) user.setEmail(req.email());
        userRepo.save(user);
    }

    /**
     * Update the current user's password. This action not only updates the password hash,
     * but also increments the token version to invalidate all existing JWTs for the user.
     * @param req the new password
     * @param user the current user, injected from Spring's security context
     * @return the new access and refresh tokens
     * @throws IllegalArgumentException if the new password is the same as the current one
     */
    @Transactional
    public UpdateCurrentUserPasswordResponse updateCurrentUserPassword(
            final UpdateCurrentUserPasswordRequest req,
            final AppUser user
    ) {
        final var isSame = passwordEncoder.matches(req.newPassword(), user.getPasswordHash());
        if (isSame) throw new IllegalArgumentException("New password must be different from the current one");

        user.setPasswordHash(passwordEncoder.encode(req.newPassword()));
        user.setTokenVersion(user.getTokenVersion() + 1);
        userRepo.save(user);

        final var authInfo = AuthenticationUserInfo.builder()
                .publicId(user.getPublicId())
                .username(user.getUsername())
                .tokenVersion(user.getTokenVersion())
                .build();

        final var accessToken = jwtService.generateAccessToken(authInfo);
        final var refreshToken = jwtService.generateRefreshToken(authInfo);

        return UpdateCurrentUserPasswordResponse.builder()
                .newAccessToken(accessToken)
                .newRefreshToken(refreshToken)
                .build();
    }

    @Transactional
    public void selfDeleteAccount(final AppUser user) {
        final var profile = profileRepo.findByUserId(user.getId())
                        .orElseThrow(() -> new IllegalStateException("User profile not found"));

        final var now = OffsetDateTime.now();

        profile.setDeletedAt(now);
        user.setDeletedAt(now);
        user.setDeletedBy(user);

        userRepo.save(user);
        profileRepo.save(profile);
    }


    /**
     * Generates a presigned upload URL for the user's profile picture.
     * The object is deterministic per request. New key each time to
     * avoid the browser caching stale images after an update.
     * <br>
     * This is the step 1 in the profile picture upload flow. It ends when
     * the user confirms back that the upload to the CDN was successful.
     *
     * @param contentType the content type of the image
     * @param user the current user, injected from Spring's security context
     * @return the presigned URL in the CDN to upload the image
     */
    public ProfilePictureUploadResponse requestUpload(
            final String contentType,
            final AppUser user
    ) {
        final var extension = extractExtension(contentType);
        final var objectKey = "%s/%s/%d-%s.%s".formatted(
                storagePath,
                user.getPublicId(),
                System.currentTimeMillis(),
                UUID.randomUUID().toString().substring(0,8),
                extension
        );

        final var uploadUrl = storage.generateUploadUrl(objectKey);

        return ProfilePictureUploadResponse.builder()
                .uploadUrl(uploadUrl)
                .objectKey(objectKey)
                .expiresAt(OffsetDateTime.now().plusSeconds(presignedUrlExpirationSeconds))
                .build();
    }


    /**
     * This is step 2 in the profile picture upload flow.
     * The client confirms the upload is completed. The server verifies
     * the object exists in the CDN before updating the profile.
     * @param objectKey the CDN unique object key of the image
     * @param user the current user, injected from Spring's security context
     * @return the URL of the uploaded image to be downloaded
     * @throws UnauthorizedException if the requested object does not belong to the current user
     * @throws IllegalStateException if the user profile is not found
     */
    @Transactional
    public ProfilePictureConfirmResponse confirmUpload(
            final String objectKey,
            final AppUser user
    ) {
        // Verify ownership of the object
        final var profile = profileRepo.findByUserId(user.getId())
                .orElseThrow(() -> new IllegalStateException("User profile not found"));

        if (!objectKey.startsWith(storagePath + "/" + user.getPublicId())) {
            throw new UnauthorizedException(
                    HttpStatus.UNAUTHORIZED,
                    "Invalid object key" // Don't leak the existence of the object
            );
        }

        if (!storage.objectExists(objectKey)) {
            throw new UnauthorizedException(
                    HttpStatus.NOT_FOUND,
                    "Object not found. Upload may not have completed."
            );
        }

        // Update the profile and return a presign URL for immediate display in the frontend
        profile.setProfilePictureUrl(objectKey);
        profileRepo.save(profile);

        final var url = storage.generateDownloadUrl(objectKey);
        return new ProfilePictureConfirmResponse(url);
    }


    private String extractExtension(final String contentType) {
        return switch (contentType.toLowerCase()) {
            case "image/jpeg" -> "jpeg";
            case "image/jpg" -> "jpg";
            case "image/png" -> "png";
            case "image/webp" -> "webp";
            case "image/gif" -> "gif";
            case "image/avif" -> "avif";
            default -> throw new UnauthorizedException(
                    HttpStatus.UNSUPPORTED_MEDIA_TYPE,
                    "Unsupported image type: " + contentType
            );
        };
    }
}