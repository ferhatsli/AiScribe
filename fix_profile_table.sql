-- Önce Row Level Security'i devre dışı bırakalım
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE tokens DISABLE ROW LEVEL SECURITY;

-- Eski profil tablosunu yedekleyelim ve silelim (isteğe bağlı)
-- CREATE TABLE profiles_backup AS SELECT * FROM profiles;
-- DROP TABLE profiles; -- Bu komut çalışmayabilir çünkü yabancı anahtar kısıtlamaları var

-- Alternatif olarak, profiller tablosunu kullanıcılar tablosuna referans vermeden yeniden oluşturalım
-- (var olan bir tabloyu silip yeniden oluşturmak yerine, cascade constraint kullanarak güncelliyoruz)
ALTER TABLE profiles 
DROP CONSTRAINT IF EXISTS profiles_id_fkey CASCADE;

-- Tekrar kullanıcılar tablosuna referans vererek yabancı anahtar ekle
-- (ancak daha esnek bir şekilde)
ALTER TABLE profiles
ADD CONSTRAINT profiles_id_fkey 
FOREIGN KEY (id) REFERENCES users(id) 
ON DELETE CASCADE 
DEFERRABLE INITIALLY DEFERRED;

-- Row Level Security politikalarını güncelle
CREATE POLICY "Anyone can insert/update profiles" ON profiles
    FOR ALL USING (true) WITH CHECK (true);
    
CREATE POLICY "Anyone can insert/update users" ON users
    FOR ALL USING (true) WITH CHECK (true);
    
CREATE POLICY "Anyone can manage tokens" ON tokens
    FOR ALL USING (true) WITH CHECK (true);
    
-- RLS'i tekrar etkinleştir ama daha esnek politikalarla
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE tokens ENABLE ROW LEVEL SECURITY; 