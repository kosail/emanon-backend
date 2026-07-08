package com.korealm.emanon.shared.exceptions;

import org.springframework.http.HttpStatus;

public class UnauthorizedException extends DomainException {
    public UnauthorizedException(HttpStatus httpStatus, String message) {
        super(httpStatus, message);
    }
}
