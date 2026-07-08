package com.korealm.emanon.auth.web;

import com.korealm.emanon.auth.internal.data.dto.*;
import com.korealm.emanon.auth.internal.user.AuthUserService;
import com.korealm.emanon.shared.security.SecurityHelper;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {
    private final AuthUserService service;

    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(
            @Valid @RequestBody LoginRequest req,
            HttpServletRequest httpServletRequest
    ) {
        final var meta = new RequestMetadata(
                SecurityHelper.getClientIpAddress(httpServletRequest),
                httpServletRequest.getHeader("User-Agent")
        );

        final var res = service.loginUser(req, meta);
        return ResponseEntity.ok(res);
    }

    @PostMapping("/register")
    public ResponseEntity<CreateUserResponse> registerNewUser(
            @Valid @RequestBody CreateUserRequest req
    ) {
        final var res = service.registerNewUser(req);
        return ResponseEntity.ok(res);
    }

    // REFRESH JWT

    // LOGOUT

    // FORGOT PASSWORD
}
