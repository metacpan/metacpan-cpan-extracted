#!perl
package main;
use strict;
use Weather::MOSMIX;
use JSON 'encode_json';
use Weather::MOSMIX;
use Getopt::Long;

our $VERSION = '0.03';

GetOptions(
    'dsn=s'   => \my $dsn,
);

$dsn ||= 'dbi:SQLite:dbname=mosmix-forecast.sqlite';
my $w = Weather::MOSMIX->new(
    dbh => {
        dsn => $dsn
    },
);

my $f = $w->locations();
binmode STDOUT, ':encoding(UTF-8)';
print encode_json($f);
