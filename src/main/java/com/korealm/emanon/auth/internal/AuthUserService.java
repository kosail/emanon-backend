package com.korealm.emanon.auth.internal;

import com.korealm.emanon.auth.api.UserLookupPort;
import com.korealm.emanon.auth.internal.data.models.AppUser;
import com.korealm.emanon.auth.internal.data.repositories.AppUserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthUserService implements UserLookupPort {
    private final AppUserRepository repo;

    @Override
    public AppUser findActiveById(Long userId) {
        return repo.findByIdAndDeletedAtIsNull(userId)
                .orElseThrow();
    }
}
