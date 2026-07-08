package com.korealm.emanon.security.jwt;

import com.korealm.emanon.auth.AuthenticationPort;
import com.korealm.emanon.security.TokenResolver;
import com.korealm.emanon.shared.exceptions.UnauthorizedException;
import lombok.RequiredArgsConstructor;
import org.jspecify.annotations.NullMarked;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

import java.util.UUID;

@NullMarked
@Component
@RequiredArgsConstructor
public class DefaultTokenResolver implements TokenResolver {

    private final JwtService jwtService;
    private final AuthenticationPort authenticationPort;

    @Override
    public UserDetails resolveToken(String token) {
        // 1. Validate the refresh token cryptographically
        if (!jwtService.isTokenValid(token)) {
            throw new UnauthorizedException(HttpStatus.UNAUTHORIZED, "Invalid refresh token");
        }

        // 2. Resolve the user
        final var publicId = UUID.fromString(jwtService.extractSubject(token));
        final var userDetails = authenticationPort.loadUserByUsername(publicId);

        // 3. Check token_version match
        final var tokenVersion = jwtService.extractTokenVersion(token);
        final var userTokenVersion = authenticationPort.getAuthenticationUserInfo(userDetails).tokenVersion();

        if (!tokenVersion.equals(userTokenVersion)) {
            throw new UnauthorizedException(HttpStatus.UNAUTHORIZED, "Invalid refresh token");
        }

        return userDetails;
    }
}
