package com.korealm.emanon.security;

import com.korealm.emanon.security.data.ApiErrorDto;
import com.korealm.emanon.shared.exceptions.DomainException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import software.amazon.awssdk.core.exception.SdkClientException;
import software.amazon.awssdk.core.exception.SdkException;

import java.time.LocalDateTime;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(DomainException.class)
    public ResponseEntity<ApiErrorDto> handleErrorResponse(DomainException err) {
        final var apiError = ApiErrorDto.builder()
                .timestamp(err.getTimestamp())
                .message(err.getErrorMessage())
                .build();

        return ResponseEntity
                .status(err.getHttpStatus().value())
                .body(apiError);
    }

    @ExceptionHandler(SdkClientException.class)
    public ResponseEntity<ApiErrorDto> handleStorageErrorResponse(SdkException err) {
        final var apiError = ApiErrorDto.builder()
                .timestamp(LocalDateTime.now())
                .message(err.getMessage())
                .build();

        return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(apiError);
    }
}
