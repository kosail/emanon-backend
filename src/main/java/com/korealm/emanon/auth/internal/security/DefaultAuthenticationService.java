package com.korealm.emanon.auth.internal.security;

import com.korealm.emanon.auth.AuthenticationPort;
import com.korealm.emanon.auth.AuthenticationUserInfo;
import com.korealm.emanon.auth.internal.data.models.AppUser;
import com.korealm.emanon.auth.internal.data.repositories.AppUserRepository;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import lombok.RequiredArgsConstructor;
import org.jspecify.annotations.NullMarked;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.UUID;

@NullMarked
@Service
@RequiredArgsConstructor
public class DefaultAuthenticationService implements UserDetailsService, AuthenticationPort {
    private final AppUserRepository repo;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        final var user = repo
                .findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found:" + username));

        return new AppUserDetailsAdapter(user);
    }

    @Override
    public UserDetails loadUserByUsername(UUID id) throws UsernameNotFoundException {
        final var user = repo
                .findByPublicId(id)
                .orElseThrow(() -> new UsernameNotFoundException("User not found:" + id));

        return new AppUserDetailsAdapter(user);
    }

    @Override
    public AuthenticationUserInfo getAuthenticationUserInfo(@Valid @NotNull UserDetails userDetails) {
        final AppUser user;

        if (userDetails instanceof AppUserDetailsAdapter) {
            user = ((AppUserDetailsAdapter) userDetails).user();
        } else {
            final var username = userDetails.getUsername();
            user = repo
                    .findByUsername(username)
                    .orElseThrow(() -> new UsernameNotFoundException("User not found:" + username));
        }


        return AuthenticationUserInfo.builder()
                .publicId(user.getPublicId())
                .username(user.getUsername())
                .tokenVersion(user.getTokenVersion())
                .build();
    }


}
