package com.korealm.emanon.auth.internal.security;

import com.korealm.emanon.auth.internal.data.repositories.AppUserRepository;
import lombok.RequiredArgsConstructor;
import org.jspecify.annotations.NullMarked;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@NullMarked
@Service
@RequiredArgsConstructor
public class EmanonUserDetailsService implements UserDetailsService {
    private final AppUserRepository repo;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        var user = repo
                .findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found:" + username));

        return new AppUserDetailsAdapter(user);
    }
}
