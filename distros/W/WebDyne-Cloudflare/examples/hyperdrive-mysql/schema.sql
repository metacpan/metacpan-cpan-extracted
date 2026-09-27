CREATE TABLE demo_inventory (
    sku VARCHAR(40) PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    quantity INTEGER NOT NULL
) ENGINE=InnoDB;
INSERT INTO demo_inventory VALUES ('EVENT-001', 'Club dinner', 20);
