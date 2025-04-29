-- =============================================
-- Vsi sql ukazi, ki sem jih uporabil
-- =============================================

-- 1: Kreiranje podatkovne baze
-- treba izvesti na koordinatorju in vseh delovnih vozliščih
CREATE DATABASE myappdb;

-- 2: Priklop na bazo
\c myappdb

-- 3: Kreiranje Citus razširitve na koordinatorju
CREATE EXTENSION IF NOT EXISTS citus;

-- 4: Registracija delovnih vozlišč na koordinatorju
-- treba izvesti samo na koordinatorju
SELECT * from master_add_node('citus-worker-0.citus-worker', 5432);
SELECT * from master_add_node('citus-worker-1.citus-worker', 5432);

-- 5: Preverjanje registriranih delovnih vozlišč
SELECT * FROM master_get_active_worker_nodes();

-- 6: Kreiranje tabele uporabnikov, ki bo distribuirana po ID-ju
CREATE TABLE users (
  id serial PRIMARY KEY,
  name text NOT NULL,
  email text NOT NULL,
  created_at timestamp DEFAULT now()
);

-- 7: Kreiranje tabele naročil s povezavo na uporabnike
-- Tabela bo distribuirana po user_id
CREATE TABLE orders (
  id serial,
  user_id integer NOT NULL,
  amount numeric(10,2),
  created_at timestamp DEFAULT now(),
  PRIMARY KEY (id, user_id)
);

-- 8: Distribucija (shardanje) tabele uporabnikov po ID-ju
SELECT create_distributed_table('users', 'id');

-- 9: Distribucija tabele naročil po user_id
SELECT create_distributed_table('orders', 'user_id');

-- 10: Vnos testnih uporabnikov
INSERT INTO users (name, email) VALUES 
  ('Janez Novak', 'janez@example.com'),
  ('Ana Kovač', 'ana@example.com'),
  ('Marko Horvat', 'marko@example.com'),
  ('Maja Zupan', 'maja@example.com'),
  ('Peter Krajnc', 'peter@example.com');

-- 11: Vnos testnih naročil
INSERT INTO orders (user_id, amount) VALUES
  (1, 99.99),
  (1, 45.50),
  (2, 199.99),
  (3, 25.00),
  (4, 149.95),
  (5, 75.25),
  (1, 35.99);

-- 12: Preverjanje distribucije podatkov - število vrstic po tabelah
SELECT 'users' AS table_name, COUNT(*) AS row_count FROM users
UNION ALL
SELECT 'orders' AS table_name, COUNT(*) AS row_count FROM orders;

-- 13: Preverjanje shardanja - pregled shardov po tabeli in vozlišču
SELECT
  logicalrelid::regclass AS table_name,
  nodename,
  count(*) as shard_count
FROM pg_dist_shard
JOIN pg_dist_placement USING (shardid)
JOIN pg_dist_node ON nodeId = nodeid
GROUP BY logicalrelid, nodename
ORDER BY table_name, nodename;

-- 14: Testna JOIN poizvedba preko distribuiranih tabel
-- izvaja se distribuirano na vozliščih
SELECT 
  u.id, 
  u.name, 
  COUNT(o.id) as order_count, 
  SUM(o.amount) as total_spent
FROM users u
JOIN orders o ON u.id = o.user_id
GROUP BY u.id, u.name
ORDER BY total_spent DESC;

-- 15: EXPLAIN za JOIN poizvedbo - za prikaz distribuiranega izvajanja
EXPLAIN ANALYZE
SELECT u.name, o.amount
FROM users u
JOIN orders o ON u.id = o.user_id
WHERE u.id = 1;
