-- Ajouter un champ liquidated aux positions fournies s'il n'existe pas déjà
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'supplied_positions' AND column_name = 'liquidated'
    ) THEN
        ALTER TABLE supplied_positions
        ADD COLUMN liquidated BOOLEAN NOT NULL DEFAULT false;
    END IF;
END $$;

-- Ajouter un champ liquidated aux positions empruntées s'il n'existe pas déjà
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'borrowed_positions' AND column_name = 'liquidated'
    ) THEN
        ALTER TABLE borrowed_positions
        ADD COLUMN liquidated BOOLEAN NOT NULL DEFAULT false;
    END IF;
END $$;

-- Créer un index pour accélérer les requêtes filtrant sur liquidated s'il n'existe pas déjà
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'idx_supplied_positions_liquidated'
    ) THEN
        CREATE INDEX idx_supplied_positions_liquidated ON supplied_positions(liquidated);
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'idx_borrowed_positions_liquidated'
    ) THEN
        CREATE INDEX idx_borrowed_positions_liquidated ON borrowed_positions(liquidated);
    END IF;
END $$; 