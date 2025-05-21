-- RLS politikalarını önce kaldır
DROP POLICY IF EXISTS "Users can view their own data" ON users;
DROP POLICY IF EXISTS "Profiles are viewable by users who created them" ON profiles;
DROP POLICY IF EXISTS "Profiles can be updated by users who created them" ON profiles;
DROP POLICY IF EXISTS "Tokens are viewable by users who created them" ON tokens;

-- Daha liberal INSERT politikaları ekle
CREATE POLICY "Anyone can insert a user" ON users
    FOR INSERT WITH CHECK (true);
    
CREATE POLICY "Users can view their own data" ON users
    FOR SELECT USING (auth.uid()::text = id::text OR auth.uid() IS NULL);

CREATE POLICY "Anyone can insert a profile" ON profiles
    FOR INSERT WITH CHECK (true);
    
CREATE POLICY "Users can view profiles" ON profiles
    FOR SELECT USING (true);
    
CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (auth.uid()::text = id::text OR auth.uid() IS NULL);

CREATE POLICY "Anyone can insert a token" ON tokens
    FOR INSERT WITH CHECK (true);
    
CREATE POLICY "Users can view tokens" ON tokens
    FOR SELECT USING (true);
    
CREATE POLICY "Users can delete their tokens" ON tokens
    FOR DELETE USING (true);

-- Alternatif olarak, RLS'i tamamen devre dışı bırakma (geliştirme ortamı için)
-- ALTER TABLE users DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE tokens DISABLE ROW LEVEL SECURITY;

-- Ayrıca service_role yetkilerini kullanabilmek için aşağıdaki satırları da ekleyebilirsiniz
ALTER TABLE users FORCE ROW LEVEL SECURITY;
ALTER TABLE profiles FORCE ROW LEVEL SECURITY;
ALTER TABLE tokens FORCE ROW LEVEL SECURITY; 