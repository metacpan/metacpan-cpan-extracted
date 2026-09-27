-- PostgreSQL fixture: run in the dedicated test database as its owner.
-- Re-running preserves existing rows; this is not a destructive reset.
BEGIN;

CREATE SCHEMA IF NOT EXISTS webdyne_hyperdrive_test;

CREATE TABLE IF NOT EXISTS webdyne_hyperdrive_test.samples (
    id INTEGER PRIMARY KEY,
    label TEXT NOT NULL UNIQUE,
    note TEXT,
    enabled BOOLEAN NOT NULL,
    large_integer BIGINT NOT NULL,
    amount NUMERIC(30, 10) NOT NULL,
    measured DOUBLE PRECISION NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL,
    local_time TIMESTAMP NOT NULL,
    calendar_date DATE NOT NULL,
    document JSONB,
    tags TEXT[],
    payload BYTEA,
    external_id UUID NOT NULL UNIQUE
);

INSERT INTO webdyne_hyperdrive_test.samples
    (id, label, note, enabled, large_integer, amount, measured, recorded_at,
     local_time, calendar_date, document, tags, payload, external_id)
VALUES
    (1, 'ordinary', 'Synthetic fixture', TRUE, 42, 123.4500000000, 1.25,
     '2026-01-15T10:20:30.123456+10:30', '2026-01-15 10:20:30.123456', '2026-01-15',
     '{"name":"fixture","count":2,"active":true,"optional":null,"nested":{"items":[1,"two",false]}}',
     ARRAY['alpha','beta'], decode('00017f80ff','hex'), '00000000-0000-4000-8000-000000000001'),
    (2, 'Unicode — café 日本語 🐪', 'Quotes: ''single'' and "double"; backslash: ' || chr(92) || chr(10) || 'second line',
     FALSE, 9007199254740993, 12345678901234567890.1234567890, -0.125,
     '2024-02-29T23:59:59.999999Z', '2024-02-29 23:59:59.999999', '2024-02-29',
     '{"text":"café 日本語 🐪","type":"blob","base64":"ordinary JSON, not binary"}',
     ARRAY['café','日本語','🐪'], decode('00ff00414243','hex'), '00000000-0000-4000-8000-000000000002'),
    (3, 'nulls', NULL, TRUE, -9223372036854775808, -0.0000000001, 0,
     '2000-01-01T00:00:00Z', '2000-01-01 00:00:00', '2000-01-01',
     NULL, NULL, NULL, '00000000-0000-4000-8000-000000000003'),
    (4, 'empty', '', FALSE, 9223372036854775807, 0, 0,
     '2030-12-31T23:59:59Z', '2030-12-31 23:59:59', '2030-12-31',
     '{}'::jsonb, ARRAY[]::text[], decode('','hex'), '00000000-0000-4000-8000-000000000004'),
    (5, 'json-null', 'JSON null differs from SQL NULL', TRUE, 0, -999.9900000000, 1.5,
     '2026-06-01T12:00:00Z', '2026-06-01 12:00:00', '2026-06-01',
     'null'::jsonb, ARRAY['',NULL,'last'], decode('c3a9','hex'), '00000000-0000-4000-8000-000000000005')
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS webdyne_hyperdrive_test.items (
    id INTEGER PRIMARY KEY,
    sample_id INTEGER NOT NULL REFERENCES webdyne_hyperdrive_test.samples(id),
    sku TEXT NOT NULL UNIQUE,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(12, 2) NOT NULL CHECK (unit_price >= 0)
);

INSERT INTO webdyne_hyperdrive_test.items (id, sample_id, sku, quantity, unit_price)
VALUES (1, 1, 'ITEM-A', 2, 12.50), (2, 1, 'ITEM-B', 1, 5.00), (3, 2, 'ITEM-C', 3, 0.10)
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS webdyne_hyperdrive_test.transaction_probe (
    run_token TEXT NOT NULL,
    slot INTEGER NOT NULL CHECK (slot >= 0),
    value TEXT NOT NULL,
    PRIMARY KEY (run_token, slot)
);

COMMIT;
