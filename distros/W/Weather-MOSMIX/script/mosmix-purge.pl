#!perl
use strict;
use warnings;
use Weather::MOSMIX::Writer;
use Getopt::Long;

our $VERSION = '0.03';

GetOptions(
    'dsn=s'   => \my $dsn,

    'verbose' => \my $verbose,
);

$dsn ||= 'dbi:SQLite:dbname=mosmix-forecast.sqlite';

my $w = Weather::MOSMIX::Writer->new(
    dbh => {
        dsn => $dsn,
    }
);
$w->purge_outdated_expired_records();
