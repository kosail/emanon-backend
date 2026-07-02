package com.korealm.emanon.shared.api;

import lombok.Builder;

import java.time.LocalDateTime;

@Builder
public record ApiErrorDto(
        LocalDateTime timestamp,
        String message
) {}
