package com.korealm.emanon.auth.api;

import com.korealm.emanon.auth.internal.data.models.AppUser;

public interface UserLookupPort {

    /** Returns the user if active (deleted_at is null). Throws if not found. TODO: This SHOULD NOT leak out AppUser entity. Check on this later on */
    AppUser findActiveById(Long userId);

}
