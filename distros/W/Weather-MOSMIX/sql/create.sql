-- SQL DDL for creating the weather database
-- currently we need the JSON1 extension for SQLite (built-in with most SQLite libs since 3.9)
-- Run as
-- run-sql.pl sql/create.sql --dsn dbi:SQLite:dbname=db/forecast.sqlite

-- forecast_location -*> forecast
create table forecast_location (
      name varchar(64) not null unique
	, id integer unique not null primary key
	-- the exact positions
    , latitude double
    , longitude double
    , elevation double
    , description varchar(128) not null
);

create table forecast (
	  name varchar(64) not null
	, expiry datetime not null
	, issuetime datetime not null
    , forecasts varchar(65536) -- we store the parsed forecasts as JSON instead of row(s) currently
    -- as I don't imagine that we'll every query for them instead of locations
);

-- here we will store the last requests, which we will use to extract
-- and cache the forecasts around, instead of keeping all forecasts around
create table forecast_request (
      last_requested_at datetime not null
    , latitude double
    , longitude double
);

-- The rtree we will use to speed up finding the forecast closest to us
-- later, when I get to actually understand/use it
CREATE VIRTUAL TABLE forecast_index USING rtree(
   id,              -- Integer primary key
   minX, maxX,      -- Minimum and maximum X coordinate
   minY, maxY       -- Minimum and maximum Y coordinate
);
