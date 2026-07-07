package com.korealm.emanon.shared.exceptions;

import lombok.Builder;
import lombok.Getter;
import org.springframework.http.HttpStatus;

import java.time.LocalDateTime;

@Getter
@Builder
public class DomainException extends RuntimeException {
    private final LocalDateTime timestamp = LocalDateTime.now();
    private final HttpStatus httpStatus;
    private final String errorMessage;

    public DomainException(HttpStatus httpStatus, String errorMessage) {
        this.httpStatus = httpStatus;
        this.errorMessage = errorMessage;
        super(errorMessage);
    }
}