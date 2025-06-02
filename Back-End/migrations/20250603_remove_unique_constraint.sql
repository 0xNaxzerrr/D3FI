-- Supprimer la contrainte d'unicité sur les positions fournies
ALTER TABLE supplied_positions
DROP CONSTRAINT IF EXISTS supplied_positions_user_address_asset_id_key;

-- Supprimer la contrainte d'unicité sur les positions empruntées
ALTER TABLE borrowed_positions
DROP CONSTRAINT IF EXISTS borrowed_positions_user_address_asset_id_key;

-- Créer un nouvel index non unique pour maintenir les performances
CREATE INDEX IF NOT EXISTS idx_supplied_positions_user_asset ON supplied_positions(user_address, asset_id);
CREATE INDEX IF NOT EXISTS idx_borrowed_positions_user_asset ON borrowed_positions(user_address, asset_id); 