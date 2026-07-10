package com.korealm.emanon.shared;

import jakarta.validation.constraints.NotBlank;

public interface StorageService {
    /**
     * Generates a presigned PUT URL. Client uses this to upload directly to the CDN.
     * The URL is scoped to the exact object key and cannot upload to any other path.
     * <br>
     * Never returns <code>null</code>.
     */
    String generateUploadUrl(@NotBlank final String objectKey);

    /**
     * Generates a presigned GET URL for downloading/displaying an object.
     * <br>
     * Never returns <code>null</code>.
     */
    String generateDownloadUrl(@NotBlank final String objectKey);

    /**
     * Verifies an object exists in the bucket. Used during the confirmation step.
     */
    boolean objectExists(@NotBlank final String objectKey);

    /**
     * Deletes an object from the bucket. S3's `deleteObject` is idempotent, and
     * deleting a key that doesn't exist returns HTTP 204 success.
     * <br>
     * Never returns <code>null</code>.
     */
    void deleteObject(@NotBlank final String objectKey);
}
