#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

use lib 'ex'; # Where OtherBeerDB should live

BEGIN 
{
    my $dbi_driver = 'SQLite';    
    eval "require DBD::SQLite";
    $dbi_driver = 'SQLite2' if $@;
    eval "require DBD::SQLITE2" if $@;
    
    Test::More->import( skip_all =>
        "SQLite not working: $@"
    ) if $@;

    plan tests => 3;
    
    die sprintf "SQLite datasource '%s' not found, correct the path or "
        . "recreate the database by running Makefile.PL", 't/other_beerdb.db'
            unless -e 't/other_beerdb.db';
    
    use_ok( 'Test::WWW::Mechanize::Maypole', 'OtherBeerDB', 'dbi', $dbi_driver, 't/other_beerdb.db' );
}

$ENV{MAYPOLE_TEMPLATES} = "t/templates";

# view - new beer
{
    my $mech = Test::WWW::Mechanize::Maypole->new;
    $mech->get("http://localhost/beerdb/beer/view/2");
    
    $mech->content_contains( 'Organic Worst Bitter' );
}

# view - old beer
{
    my $mech = Test::WWW::Mechanize::Maypole->new;
    $mech->get("http://localhost/beerdb/beer/view/1");
    
    $mech->content_contains( 'Organic Best Bitter' );
}



