package com.korealm.emanon.shared;

public interface StorageService {
    /**
     * Generates a presigned PUT URL. Client uses this to upload directly to the CDN.
     * The URL is scoped to the exact object key and cannot upload to any other path.
     */
    String generateUploadUrl(String objectKey);

    /**
     * Generates a presigned GET URL for downloading/displaying an object.
     */
    String generateDownloadUrl(String objectKey);

    /**
     * Verifies an object exists in the bucket. Used during the confirmation step.
     */
    boolean objectExists(String objectKey);
}
