#!perl
use strict;
use warnings;
use Weather::MOSMIX::Writer;
use Weather::MOSMIX::Reader;

use HTTP::Tiny;
use File::Temp 'tempfile';

use Getopt::Long;

our $VERSION = '0.03';

GetOptions(
    'create'  => \my $create,
    'import'  => \my $import,
    'fetch'   => \my $fetch,

    'dsn=s'   => \my $dsn,

    'verbose' => \my $verbose,
);

$dsn ||= 'dbi:SQLite:dbname=mosmix-forecast.sqlite';
my $delete;
my @delete;

sub status {
    if( $verbose ) {
        print "@_\n";
    };
};

my %actions;

if( @ARGV) {
    $import = 1;
};

if( ! ($create || $import || $fetch )) {
    $fetch = 1;
    $import = 1;
    $delete = 1;
};
$actions{ create } = $create;
$actions{ import } = $import;
$actions{ fetch  } = $fetch;
my @files = @ARGV;

my $w;
if( $actions{ create }) {
    $w ||= Weather::MOSMIX::Writer->new();
    $w->create_db(
        dsn => $dsn
    );
}

if( $actions{ fetch }) {
    my $base = 'https://opendata.dwd.de/weather/local_forecasts/mos/MOSMIX_S/all_stations/kml/MOSMIX_S_LATEST_240.kmz';
    status( "Fetching $base" );

    my $ua = HTTP::Tiny->new();
    my( $fh, $name ) = tempfile();
    close $fh;

    my $res = $ua->mirror($base => $name);

    if( ! $res->{success}) {
        die $res->{message};
    };
    status( join " ", "Fetched", -s($name), "bytes to $name" );

    push @files, $name;
    push @delete, $name if  $delete
};

if( $actions{ import }) {
    $w ||= Weather::MOSMIX::Writer->new(
        dbh => {
            dsn => $dsn,
        }
    );
    my $r = Weather::MOSMIX::Reader->new(
        writer => $w,
    );

    for my $file (@files) {
        status("Importing $file\n");
        $r->read_zip( $file );
    };
}
unlink @delete;
