#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 1;

ok(1); # need at least 1 test to keep everything happy

# -----------------------------------------------------------------------------
# stolen from Maypole Makefile.PL

my $sql = join( '', (<DATA>) );

foreach my $beerdb ( qw/ beerdb.db other_beerdb.db / )
{    
    diag "Making SQLite DB\n";
    
    unlink "t/$beerdb";
    
    my $driver = 'SQLite';
    eval { require DBD::SQLite } or do {
        print "Error loading DBD::SQLite, trying DBD::SQLite2\n";
        eval {require DBD::SQLite2} ? $driver = 'SQLite2'
            : die "DBD::SQLite2 is not installed";
    };
    require DBI;
    my $dbh = DBI->connect("dbi:$driver:dbname=t/$beerdb");
    #my $sql = join( '', (<DATA>) );

    for my $statement ( split /;/, $sql ) {
        $statement =~ s/\#.*$//mg;           # strip # comments
        $statement =~ s/auto_increment//g;
        next unless $statement =~ /\S/;
        #warn $statement;
        eval { $dbh->do($statement) };
        die "$@: $statement" if $@;
    }

    if ( $beerdb eq 'other_beerdb.db' )
    {
        my $statement = 'INSERT INTO beer (id, brewery, name, abv) ' .
            'VALUES (2, 12, "Organic Worst Bitter", "4.1")';
        #warn $statement;
        eval { $dbh->do($statement) };
        die "$@: $statement" if $@;
    }
    
}


__DATA__

create table brewery (
    id integer auto_increment primary key,
    name varchar(30),
    url varchar(50),
    notes text
);

create table beer (
    id integer auto_increment primary key,
    brewery integer,
    style integer,
    name varchar(30),
    url varchar(120),
#    tasted date,
    score integer(2),
    price varchar(12),
    abv varchar(10),
    notes text
);

create table handpump (
    id integer auto_increment primary key,
    beer integer,
    pub integer
);

create table pub (
    id integer auto_increment primary key,
    name varchar(60),
    url varchar(120),
    notes text
);

create table style (
    id integer auto_increment primary key,
    name varchar(60),
    notes text
);

INSERT INTO beer (id, brewery, name, abv) VALUES
    (1, 1, "Organic Best Bitter", "4.1");
INSERT INTO brewery (id, name, url) VALUES
    (1, "St Peter's Brewery", "http://www.stpetersbrewery.co.uk/");
INSERT INTO pub (id, name) VALUES (1, "Turf Tavern");
INSERT INTO handpump (id, pub, beer) VALUES (1, 1,1);

