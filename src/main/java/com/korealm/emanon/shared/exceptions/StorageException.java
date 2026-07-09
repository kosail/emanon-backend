package com.korealm.emanon.shared.exceptions;

import org.springframework.http.HttpStatus;

public class StorageException extends DomainException {
    public StorageException(String message, Throwable cause) {
        super(HttpStatus.INTERNAL_SERVER_ERROR, message);
        initCause(cause);
    }
}
