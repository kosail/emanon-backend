package com.korealm.emanon.auth.web;

import com.korealm.emanon.auth.internal.AuthUserService;
import com.korealm.emanon.auth.internal.data.dto.LoginRequestDto;
import com.korealm.emanon.auth.internal.data.dto.LoginResponseDto;
import com.korealm.emanon.auth.internal.data.dto.RequestMetadata;
import com.korealm.emanon.shared.security.SecurityHelper;
import jakarta.servlet.http.HttpServletRequest;
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

    // LOGIN
    @PostMapping("/login")
    public ResponseEntity<LoginResponseDto> login(@RequestBody LoginRequestDto req, HttpServletRequest httpServletRequest) {
        final var meta = new RequestMetadata(
                SecurityHelper.getClientIpAddress(httpServletRequest),
                httpServletRequest.getHeader("User-Agent")
        );

        return ResponseEntity.ok(service.loginUser(req, meta));
    }

    // REFRESH JWT

    // LOGOUT

    // FORGOT PASSWORD
}
