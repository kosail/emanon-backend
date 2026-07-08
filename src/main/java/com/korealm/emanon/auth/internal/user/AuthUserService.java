package com.korealm.emanon.auth.internal.user;

import com.korealm.emanon.auth.api.UserLookupPort;
import com.korealm.emanon.auth.internal.data.dto.*;
import com.korealm.emanon.auth.internal.data.models.AppUser;
import com.korealm.emanon.auth.internal.data.models.AppUserProfile;
import com.korealm.emanon.auth.internal.data.models.LoginHistory;
import com.korealm.emanon.auth.internal.data.repositories.AppUserProfileRepository;
import com.korealm.emanon.auth.internal.data.repositories.AppUserRepository;
import com.korealm.emanon.auth.internal.data.repositories.LoginHistoryRepository;
import com.korealm.emanon.auth.internal.exception.UnauthorizedException;
import com.korealm.emanon.auth.internal.exception.UserAlreadyExistsException;
import com.korealm.emanon.auth.internal.exception.UserNotFoundException;
import com.korealm.emanon.auth.internal.security.AppUserDetailsAdapter;
import com.korealm.emanon.auth.internal.security.JwtService;
import com.korealm.emanon.shared.exceptions.DomainException;
import com.korealm.emanon.shared.exceptions.InvalidSourceIpAddressException;
import lombok.RequiredArgsConstructor;
import org.jspecify.annotations.NullMarked;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.net.InetAddress;
import java.net.UnknownHostException;

@NullMarked
@Service
@RequiredArgsConstructor
public class AuthUserService implements UserLookupPort {

    private final AppUserRepository userRepo;
    private final AppUserProfileRepository profileRepo;
    private final LoginHistoryRepository loginHistoryRepo;

    private final JwtService jwtService;
    private final AuthenticationManager authManager;
    private final PasswordEncoder passwordEncoder;

    /**
     * Authenticates a user via Spring Security's AuthenticationManager.
     * <br>
     * On failure: logs a failed LoginHistory row, then rethrows.
     * On success: logs a successful LoginHistory row, issues JWT (placeholder).
     * <br>
     * The AuthenticationManager does: <br>
     *   1. User lookup via EmanonUserDetailsService <br>
     *   2. Deleted_at check via AppUser.isEnabled() <br>
     *   3. Password verification via BCryptPasswordEncoder <br>
     * <br>
     * We don't distinguish between failure reasons. Every failure returns
     * the same error message to prevent username enumeration.
     */
    public LoginResponse loginUser(LoginRequest req, RequestMetadata meta) {
        final var unauthenticated = new UsernamePasswordAuthenticationToken(
                req.username(), req.password()
        );

        final AppUserDetailsAdapter principal;

        try {
            // 2. Authenticate through the manager chain
            final var authenticated = authManager.authenticate(unauthenticated);
            principal = (AppUserDetailsAdapter) authenticated.getPrincipal();

        } catch (AuthenticationException ex) {
            // 3. Failure: resolve user for history logging, then record and rethrow
            final var user = userRepo.findByUsername(req.username()).orElse(null);
            final var login = generateLogin(user, meta, false);
            loginHistoryRepo.saveAndFlush(login);

            throw mapToDomainException(ex);
        }

        // 4. Success: record login history
        final AppUser user = principal.getUser();
        final var loginHistory = generateLogin(user, meta, true);

        loginHistoryRepo.save(loginHistory);

        final var token = jwtService.generateToken(principal, user.getTokenVersion());

        final var profilePicture = profileRepo.findByUserId(user.getId());
        final var profilePictureUrl = profilePicture.map(AppUserProfile::getProfilePictureUrl).orElse(null);

        return LoginResponse.builder()
                .userId(user.getPublicId())
                .username(user.getUsername())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .token(token)
                .profilePictureUrl(profilePictureUrl)
                .build();
    }

    @Transactional
    public CreateUserResponse registerNewUser(CreateUserRequest req) {
        final var existing = userRepo.findByUsernameOrEmail(req.username(), req.email());

        if (existing.isPresent()) throw new UserAlreadyExistsException(HttpStatus.CONFLICT, "User already exists");

        final var user = new AppUser();
        user.setUsername(req.username());
        user.setEmail(req.email());
        user.setFirstName(req.firstName());
        user.setLastName(req.lastName());
        user.setPasswordHash(passwordEncoder.encode(req.password()));
        userRepo.saveAndFlush(user);

        final var userProfile = new AppUserProfile();
        userProfile.setUpdatedBy(user);
        userProfile.setUser(user);
        profileRepo.save(userProfile);

        return CreateUserResponse.builder()
                .userId(user.getPublicId())
                .username(user.getUsername())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .email(user.getEmail())
                .build();
    }

    // REFRESH JWT

    // LOGOUT

    // FORGOT PASSWORD


    /**
     * Utility to help constructing a LoginHistory entry.
     *
     * @throws InvalidSourceIpAddressException  When failed at IP conversion. Login from devices that hide their IP address is strictly prohibited
     *
     */
    private LoginHistory generateLogin(
            final AppUser user,
            final RequestMetadata meta,
            final boolean isSuccess
    ) {
        final LoginHistory login = new LoginHistory();

        login.setUser(user);
        login.setUserAgent(meta.userAgent());
        login.setSuccess(isSuccess);

        try {
            login.setIpAddress(InetAddress.getByName(meta.ipAddress()));
        } catch (UnknownHostException e) {
            login.setIpAddress(null);
            throw new InvalidSourceIpAddressException(HttpStatus.BAD_REQUEST, "Invalid source in request.");
        }

        return login;
    }

    /**
     * Maps Spring Security internal exceptions to EMANON's domain exceptions.
     * All authentication failures surface as the same generic message to
     * prevent user enumeration (attacker can't tell if user doesn't exist,
     * is deactivated, or has wrong password).
     */
    private DomainException mapToDomainException(AuthenticationException ex) {
        return new UnauthorizedException(
                HttpStatus.UNAUTHORIZED,
                "Invalid username or password"
        );
    }


    @Override
    public AppUser findActiveById(Long userId) {
        return userRepo
                .findByIdAndDeletedAtIsNull(userId)
                .orElseThrow(() -> new UserNotFoundException(
                                HttpStatus.NOT_FOUND,
                                String.format("User %s not found", userId)
                        )
                );
    }

}
