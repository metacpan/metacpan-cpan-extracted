-- XXX must enable the pg_bigm extension first
CREATE EXTENSION pg_bigm;

CREATE TABLE Items(
  id   SERIAL PRIMARY KEY,
  name VARCHAR(20),
  note TEXT
);
CREATE INDEX idx_items_name ON Items USING gin (name gin_bigm_ops);
CREATE INDEX idx_items_note ON Items USING gin (note gin_bigm_ops);

INSERT INTO Items (name, note) 
VALUES 
  ('やくそう', 'HPを30回復する'),
  ('どくけしそう', 'どくを回復する'),
  ('ちからのたね', 'ちからを1上昇させる'),
  ('ラックのたね', 'うんを1上昇させる'),
  ('たけやり', 'こうげきりょく+2'),
  ('きのぼう', 'こうげきりょく+1'),
  ('なべのふた', 'ぼうぎょりょく+1'), 
  ('ぬののふく', 'ぼうぎょりょく+1')
;
