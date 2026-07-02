package com.korealm.emanon.assets.internal.data.repositories;

import com.korealm.emanon.assets.internal.data.models.AssetVersion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AssetVersionRepository extends JpaRepository<AssetVersion, Long> {
}
