package com.korealm.emanon.shared.exceptions;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import org.springframework.http.HttpStatus;

import java.time.LocalDateTime;

@Getter @Setter @Builder
public abstract class DomainException extends Throwable {
    private final LocalDateTime timestamp;
    private final HttpStatus httpStatus;
    private final String errorMessage;

    public DomainException(HttpStatus httpStatus, String errorMessage) {
        this.timestamp = LocalDateTime.now();
        this.httpStatus = httpStatus;
        this.errorMessage = errorMessage;
        super(errorMessage);
    }
}