package com.korealm.emanon.auth.internal.security;

import com.korealm.emanon.auth.internal.data.repositories.AppUserRepository;
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
public class EmanonUserDetailsService implements UserDetailsService {
    private final AppUserRepository repo;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        final var user = repo
                .findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found:" + username));

        return new AppUserDetailsAdapter(user);
    }

    public UserDetails loadUserByUsername(UUID id) throws UsernameNotFoundException {
        final var user = repo
                .findByPublicId(id)
                .orElseThrow(() -> new UsernameNotFoundException("User not found:" + id));

        return new AppUserDetailsAdapter(user);
    }
}
