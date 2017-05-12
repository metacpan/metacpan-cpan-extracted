-- 1 up
create table users (
  id SERIAL PRIMARY KEY,
  userid TEXT NOT NULL UNIQUE,
  passwd TEXT NOT NULL UNIQUE
);

insert into users (userid, passwd) values ('root','root');
-- 1 down
drop table users;
