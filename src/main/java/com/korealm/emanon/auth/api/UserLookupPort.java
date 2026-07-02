package com.korealm.emanon.auth.api;

import com.korealm.emanon.auth.internal.data.models.AppUser;

public interface UserLookupPort {

    /** Returns the user if active (deleted_at is null). Throws if not found */
    AppUser findActiveById(Long userId);

}
