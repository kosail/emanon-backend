package com.korealm.emanon.auth.web;

import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/auth/me")
@RequiredArgsConstructor
public class CurrentUserController {

    // ME (CURRENT USER + PROFILE)

    // PROFILE (PICTURE, DESCRIPTION)

    // CHANGE PASSWORD (INCREMENTS TOKEN_VERSION)
}
