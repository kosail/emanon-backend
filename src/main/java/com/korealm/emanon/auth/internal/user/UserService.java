package com.korealm.emanon.auth.internal.user;

import com.korealm.emanon.auth.internal.data.dto.UserInfoResponse;
import com.korealm.emanon.auth.internal.data.dto.UserInfoUpdateRequest;
import com.korealm.emanon.auth.internal.data.dto.UserProfileResponse;
import com.korealm.emanon.auth.internal.data.models.AppUser;
import com.korealm.emanon.auth.internal.data.repositories.AppUserProfileRepository;
import com.korealm.emanon.auth.internal.data.repositories.AppUserRepository;
import com.korealm.emanon.auth.internal.exception.IllegalUserStateException;
import com.korealm.emanon.auth.internal.exception.UserNotFoundException;
import com.korealm.emanon.shared.StorageService;
import lombok.RequiredArgsConstructor;
import org.jspecify.annotations.NullMarked;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@NullMarked
@Service
@RequiredArgsConstructor
public class UserService {

    private final AppUserRepository userRepo;
    private final AppUserProfileRepository profileRepo;
    private final StorageService storage;

    /**
     * List all existing users, including soft-deleted ones.
     */
    @Transactional(readOnly = true)
    public List<UserInfoResponse> getAll() {
        return userRepo
                .findAll()
                .stream()
                .map(this::toUserInfoResponse)
                .toList();
    }

    /**
     * List all active users. Soft-deleted users are not included.
     */
    @Transactional(readOnly = true)
    public List<UserInfoResponse> getAllActive() {
        return userRepo
                .findAllByDeletedAtIsNullAndDeletedByIsNull()
                .stream()
                .map(this::toUserInfoResponse)
                .toList();
    }

    /**
     * Get a user's profile. This method is to retrieve a user's profile different from the logged-in user.
     * @param userId the user's public ID
     * @return The user's profile description, profile picture URL, and user basic information like names and email.
     * @throws UserNotFoundException if the user or profile is not found
     * @throws IllegalUserStateException if the user profile is not found.
     * This should never happen, because by design and concept all users must have a profile.
     */
    @Transactional(readOnly = true)
    public UserProfileResponse getProfile(final UUID userId) {
        final var user = userRepo.findByPublicId(userId)
                .orElseThrow(() -> new UserNotFoundException(
                        HttpStatus.NOT_FOUND,
                        "User not found"
                ));

        final var profile = profileRepo.findByUserId(user.getId())
                .orElseThrow(() -> new IllegalUserStateException(
                        HttpStatus.INTERNAL_SERVER_ERROR,
                        "User profile not found."
                ));

        final var profilePictureKey = profile.getProfilePictureUrl();
        final var profilePictureUrl = profilePictureKey == null || profilePictureKey.isBlank()
                ? null
                : storage.generateDownloadUrl(profilePictureKey);

        return UserProfileResponse.builder()
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .email(user.getEmail())
                .description(profile.getUserDescription())
                .profilePictureUrl(profilePictureUrl)
                .build();
    }

    /**
     * Update a user account or profile information. This method is to update a user's profile differently from
     * the logged-in user. Only admin users can perform this action.
     * @param userId The user's public ID
     * @param req The user's new information. Almost any data field of the user can be updated, except for the
     *           email, password, and profile picture (this can only be deleted, not updated).
     * @param adminUser The admin user performing the update, extracted from Spring's security context.
     * @throws UserNotFoundException if the user or profile is not found
     * @throws IllegalUserStateException if the user profile is not found.
     * This should never happen, because by design and concept all users must have a profile.
     */
    @Transactional
    public void updateUserInformation(
            final UUID userId,
            final UserInfoUpdateRequest req,
            final AppUser adminUser
    ) {
        final var user = userRepo.findByPublicId(userId)
                .orElseThrow(() -> new UserNotFoundException(
                        HttpStatus.NOT_FOUND,
                        "User not found"
                ));

        final var profile = profileRepo.findByUserId(user.getId())
                .orElseThrow(() -> new IllegalUserStateException(
                        HttpStatus.INTERNAL_SERVER_ERROR,
                        "User profile not found."
                ));

        // User account information

        if (req.firstName() != null) user.setFirstName(req.firstName());
        if (req.lastName() != null) user.setLastName(req.lastName());
        if (req.username() != null) user.setUsername(req.username());

        // Profile information

        final var profilePictureKey = profile.getProfilePictureUrl();
        if (req.removeProfilePicture() && profilePictureKey != null) {
            storage.deleteObject(profilePictureKey);
            profile.setProfilePictureUrl(null);
        }

        if (req.description() != null) profile.setUserDescription(req.description());

        user.setUpdatedBy(adminUser);
        profile.setUpdatedBy(adminUser);

        userRepo.save(user);
        profileRepo.save(profile);
    }

    /**
     * Soft-delete a user account. This method is to delete a user's account differently from the logged-in user.
     * Only admin users can perform this action.
     * @param userId the user's public ID
     * @param adminUser the admin user performing the delete, extracted from Spring's security context.
     * @throws UserNotFoundException if the user or profile is not found
     * @throws IllegalUserStateException if the user profile is not found.
     * This should never happen, because by design and concept all users must have a profile.
     */
    @Transactional
    public void deleteUserAccount(
            final UUID userId,
            final AppUser adminUser
    ) {
        final var user = userRepo.findByPublicId(userId)
                .orElseThrow(() -> new UserNotFoundException(
                        HttpStatus.NOT_FOUND,
                        "User %s not found".formatted(userId)
                ));

        final var profile = profileRepo.findByUserId(user.getId())
                .orElseThrow(() -> new IllegalUserStateException(
                        HttpStatus.INTERNAL_SERVER_ERROR,
                        "User profile not found."
                ));

        profile.setUpdatedBy(adminUser);
        user.setUpdatedBy(adminUser);
        user.setDeletedBy(adminUser);
        user.setDeletedAt(OffsetDateTime.now());

        profileRepo.save(profile);
        userRepo.save(user);
    }

    /**
     * Restores a user account that was previously marked as deleted. This method
     * sets the deletion-related fields of the user and their associated profile
     * to null, effectively making the account active again. The method assumes
     * the operation is initiated by an admin user and updates the account with
     * the admin user's details.
     *
     * @param userId The unique public ID of the user account to be restored.
     * @param adminUser The admin user performing the restoration operation.
     *                  This user will be recorded as the last updater of the restored account.
     * @throws UserNotFoundException If the user with the specified ID is not found.
     * @throws IllegalUserStateException If the user's profile is not found or in an inconsistent state.
     */
    @Transactional
    public void restoreUserAccount(
            final UUID userId,
            final AppUser adminUser
    ) {
        final var user = userRepo.findByPublicId(userId)
                .orElseThrow(() -> new UserNotFoundException(
                        HttpStatus.NOT_FOUND,
                        "User %s not found".formatted(userId)
                ));

        final var profile = profileRepo.findByUserId(user.getId())
                .orElseThrow(() -> new IllegalUserStateException(
                        HttpStatus.INTERNAL_SERVER_ERROR,
                        "User profile not found."
                ));

        profile.setDeletedAt(null);
        profile.setUpdatedAt(OffsetDateTime.now());

        user.setDeletedAt(null);
        user.setDeletedBy(null);

        user.setUpdatedBy(adminUser);
        user.setUpdatedAt(OffsetDateTime.now());

        profileRepo.save(profile);
        userRepo.save(user);
    }

    private UserInfoResponse toUserInfoResponse(final AppUser user) {
        return UserInfoResponse.builder()
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .email(user.getEmail())
                .build();
    }
}
