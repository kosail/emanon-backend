package com.korealm.emanon.security.data;

import lombok.Builder;

import java.time.LocalDateTime;

@Builder
public record ApiErrorDto(
        LocalDateTime timestamp,
        String message
) {}
