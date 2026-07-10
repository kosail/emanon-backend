package com.korealm.emanon.shared.exceptions;

import org.springframework.http.HttpStatus;

public class InvalidRequestException extends DomainException {
    public InvalidRequestException(HttpStatus httpStatus, String message) {
        super(httpStatus, message);
    }
}
