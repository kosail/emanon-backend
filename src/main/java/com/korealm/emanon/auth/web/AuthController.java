package com.korealm.emanon.auth.web;

import com.korealm.emanon.auth.internal.data.dto.*;
import com.korealm.emanon.auth.internal.data.models.AppUser;
import com.korealm.emanon.auth.internal.user.AuthService;
import com.korealm.emanon.security.SecurityHelper;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {
    private final AuthService service;

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

    @PostMapping("/refresh")
    public ResponseEntity<TokenRefreshResponse> refresh(
            @Valid @RequestBody TokenRefreshRequest req
    ) {
        final var response = service.refreshToken(req.refreshToken());
        return ResponseEntity.ok(response);
    }

    // LOGOUT
    @PostMapping("/logout")
    public ResponseEntity<Void> logout(
            @AuthenticationPrincipal AppUser user
            ) {
        service.logout(user);
        return ResponseEntity.noContent().build();
    }

    // TODO: FORGOT PASSWORD
}
