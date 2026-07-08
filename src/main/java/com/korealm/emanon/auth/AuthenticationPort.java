package com.korealm.emanon.auth;

import jakarta.validation.constraints.NotNull;
import org.jspecify.annotations.NullMarked;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;

import java.util.UUID;

@NullMarked
public interface AuthenticationPort {
    UserDetails loadUserByUsername(String username);

    /**
     * Locates the user based on the public ID, which is a <code>UUID</code>.
     * @param id the public id identifying the user whose data is required.
     * @return a fully populated user record (never <code>null</code>)
     * @throws UsernameNotFoundException if the user could not be found or the user has no
     * GrantedAuthority
     */
    UserDetails loadUserByUsername(UUID id);

    /**
     * Returns the exact required information to create a JWT for the required user.
     * This method expects the parameter to be an instance of AppUserDetailsAdapter to easily extract the user info.
     * If it is not an instance of AppUserDetailsAdapter, it fallbacks to DB lookup using the username.
     * @param userDetails the user details (user) to be used to create the JWT.
     * @return An object holding the publicId, username, and tokenVersion. It never returns <code>null</code>.
     * @throws UsernameNotFoundException if the user could not be found
     */
    AuthenticationUserInfo getAuthenticationUserInfo(@NotNull UserDetails userDetails);
}
