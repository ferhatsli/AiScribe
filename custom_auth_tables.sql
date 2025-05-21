-- Users tablosu
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    salt TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Tokens tablosu
CREATE TABLE IF NOT EXISTS tokens (
    token TEXT PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    expires BIGINT NOT NULL
);

-- Profiles tablosu (zaten varsa bu kısmı atlayabilirsiniz)
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Güvenlik politikaları
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Profil güvenlik politikaları
CREATE POLICY "Profiles are viewable by users who created them" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Profiles can be updated by users who created them" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Token güvenlik politikaları
CREATE POLICY "Tokens are viewable by users who created them" ON tokens
    FOR SELECT USING (auth.uid()::text = user_id::text);

-- Users güvenlik politikaları
CREATE POLICY "Users can view their own data" ON users
    FOR SELECT USING (auth.uid() = id); 