package com.korealm.emanon.assets.data.repositories;

import com.korealm.emanon.assets.data.models.Asset;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AssetRepository extends JpaRepository<Asset, Long> {
}
