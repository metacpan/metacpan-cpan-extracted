CREATE TABLE IF NOT EXISTS demo_inventory (
    sku TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity >= 0)
);
INSERT INTO demo_inventory (sku, name, quantity)
VALUES ('CLUB-001', 'Club dinner places', 24)
ON CONFLICT (sku) DO NOTHING;
