-- Create users table
CREATE TABLE users (
    address TEXT PRIMARY KEY,
    username TEXT,
    email TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create positions table for supplied assets
CREATE TABLE supplied_positions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_address TEXT NOT NULL REFERENCES users(address) ON DELETE CASCADE,
    asset_id UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
    amount NUMERIC NOT NULL,
    collateral BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(user_address, asset_id)
);

-- Create positions table for borrowed assets
CREATE TABLE borrowed_positions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_address TEXT NOT NULL REFERENCES users(address) ON DELETE CASCADE,
    asset_id UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
    amount NUMERIC NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(user_address, asset_id)
);

-- Create table for health factor history
CREATE TABLE health_factor_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_address TEXT NOT NULL REFERENCES users(address) ON DELETE CASCADE,
    health_factor NUMERIC NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Index for faster queries by user
CREATE INDEX idx_supplied_positions_user ON supplied_positions(user_address);
CREATE INDEX idx_borrowed_positions_user ON borrowed_positions(user_address);
CREATE INDEX idx_health_history_user ON health_factor_history(user_address);
CREATE INDEX idx_health_history_timestamp ON health_factor_history(timestamp); 