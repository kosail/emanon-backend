package com.korealm.emanon.auth.internal;

import com.korealm.emanon.auth.api.UserLookupPort;
import com.korealm.emanon.auth.internal.data.dto.LoginRequestDto;
import com.korealm.emanon.auth.internal.data.dto.LoginResponseDto;
import com.korealm.emanon.auth.internal.data.dto.RequestMetadata;
import com.korealm.emanon.auth.internal.data.models.AppUser;
import com.korealm.emanon.auth.internal.data.models.AppUserProfile;
import com.korealm.emanon.auth.internal.data.models.LoginHistory;
import com.korealm.emanon.auth.internal.data.repositories.AppUserProfileRepository;
import com.korealm.emanon.auth.internal.data.repositories.AppUserRepository;
import com.korealm.emanon.auth.internal.data.repositories.LoginHistoryRepository;
import com.korealm.emanon.auth.internal.exception.UnauthorizedException;
import com.korealm.emanon.auth.internal.exception.UserNotFoundException;
import com.korealm.emanon.shared.exceptions.InvalidSourceIpAddressException;
import com.korealm.emanon.shared.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import java.net.InetAddress;

@Service
@RequiredArgsConstructor
public class AuthUserService implements UserLookupPort {

    private final AppUserRepository userRepo;
    private final AppUserProfileRepository profileRepo;
    private final LoginHistoryRepository loginHistoryRepo;

    private final JwtService jwtService;
    private final ArgonEncoder encoder;

    public LoginResponseDto loginUser(LoginRequestDto req, RequestMetadata meta) {
        final var user = userRepo
                .findByUsername(req.username())
                .orElseThrow(() ->
                        new UnauthorizedException(HttpStatus.UNAUTHORIZED, "Invalid username or password")
                );

        // Register the login attempt in the login history
        final var loginHistory = new LoginHistory();
        loginHistory.setUser(user);
        loginHistory.setUserAgent(meta.userAgent());

        // Login from devices that hide their IP address is strictly prohibited
        try {
            loginHistory.setIpAddress(InetAddress.getByName(meta.ipAddress()));
        } catch (Exception e) {
            loginHistory.setIpAddress(null);
            loginHistory.setSuccess(false);
            loginHistoryRepo.saveAndFlush(loginHistory);
            throw new InvalidSourceIpAddressException(HttpStatus.BAD_REQUEST, "Invalid source in request.");
        }

        if (!encoder
                .passwordEncoder()
                .matches(
                        req.password(),
                        user.getPasswordHash())
        ) {
            loginHistory.setSuccess(false);
            loginHistoryRepo.saveAndFlush(loginHistory);
            throw new UnauthorizedException(HttpStatus.UNAUTHORIZED, "Invalid username or password");
        }

        loginHistory.setSuccess(true);
        loginHistoryRepo.save(loginHistory);

        UserDetails userDetails = User.builder()
                .username(user.getUsername())
                .password(user.getPasswordHash())
                .roles("USER")
                .build();

        final var token = jwtService.generateToken(userDetails, user.getTokenVersion());

        final var profilePicture = profileRepo.findByUserId(user.getId());
        final var profilePictureUrl = profilePicture.map(AppUserProfile::getProfilePictureUrl).orElse(null);

        return new LoginResponseDto(token, profilePictureUrl);
    }

    // REFRESH JWT

    // LOGOUT

    // FORGOT PASSWORD

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
