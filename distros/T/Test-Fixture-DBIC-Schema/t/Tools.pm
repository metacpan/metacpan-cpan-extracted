package t::Tools;
use strict;
use warnings;
use t::Foo;

my $schema = t::Foo->connect("dbi:SQLite:", '', '');
$schema->storage->dbh->do(
    q{
        CREATE TABLE cd (
            cdid   INTEGER,
            artist INTEGER,
            title  VARCHAR(255),
            year   INTEGER
        );
    }
);
$schema->storage->dbh->do(
    q{
        CREATE TABLE artist (
            artistid INTEGER,
            name     VARCHAR(255)
        );
    }
);
$schema->storage->dbh->do(
    q{
        CREATE VIEW view_all AS
            select cd.cdid,
                   cd.title,
                   cd.year,
                   a.artistid as artist_id,
                   a.name     as artist_name
            from cd, artist a
            where cd.artist=a.artistid;
    }
);

sub import {
    my $pkg = caller(0);
    no strict 'refs'; ## no critic.
    *{"$pkg\::schema"} = sub () {
        $schema;
    };
}


1;
