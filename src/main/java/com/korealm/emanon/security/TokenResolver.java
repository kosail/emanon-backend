package com.korealm.emanon.security;

import org.jspecify.annotations.NullMarked;
import org.springframework.security.core.userdetails.UserDetails;

@NullMarked
public interface TokenResolver {
    /**
     * Validates a JWT token and returns the corresponding user details.
     * @throws com.korealm.emanon.shared.exceptions.UnauthorizedException if the token is invalid
     */
    UserDetails resolveToken(String token);
}
