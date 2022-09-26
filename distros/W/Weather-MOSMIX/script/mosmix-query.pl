#!perl
package main;
use strict;
use Weather::MOSMIX;
use Weather::MOSMIX::Weathercodes 'mosmix_weathercode';
use Data::Dumper;
use charnames ':full';
use Time::Piece;
use Text::Table;
use Getopt::Long;

our $VERSION = '0.03';

GetOptions(
    'latitude=s'  => \my $latitude,
    'longitude=s' => \my $longitude,
    'dsn=s'       => \my $dsn,
);

$dsn ||= 'dbi:SQLite:dbname=mosmix-forecast.sqlite';

my $w = Weather::MOSMIX->new(
    dbh => {
        dsn => $dsn
    },
);
# Read location from .locationrc
# File::HomeDir
# ~/.config/.locationrc
# ~/.locationrc

$latitude //= 50.11;
$longitude //= 8.68;

my $f =
    $w->forecast_dbh(latitude => $latitude, longitude => $longitude );
my $out = $w->format_forecast_dbh( $f, 6 );

my @output;

# print the header
push @output, [map { '  ' . $out->[ $_ * 4 ]->{weekday} } 0..2];

for my $row (0..3) {
    #print $out->[$row]->{status}, " ";
    my $outrow = [];
    for my $col (0..2) {
        my $elt = $out->[ $row + $col*4 ];
        if( $elt->{status} eq 'active' ) {
            push @$outrow, sprintf "%2.0f/%2.0f\x{1F321}$Weather::MOSMIX::Weathercodes::as_emoji %s", $elt->{mintemp}-273.15, $elt->{maxtemp}-273.15, $elt->{emoji}
        } else {
            push @$outrow, " -/- ";
        }
    };
    push @output, $outrow;
}

binmode STDOUT, ':encoding(UTF-8)';
my $t = Text::Table->new( @{ shift @output } );
$t->load( @output );
print $out->[0]->{description},"\n";
print $t;

__END__

--- current weather (3day forecast)
    location      -> location2

      W
      mM

    mon wed thu
    m/M m/M m/M
    ww  ww  ww

--- 3day x4 forecast
    location       -> location2

    mon wed thu
mor m/M m/M m/M
    ww  ww  ww
mid m/M m/M m/M
    ww  ww  ww
eve m/M m/M m/M
    ww  ww  ww
nig m/M m/M m/M
    ww  ww  ww

--- all locations
    location  / W / mM ^ current weather (3day)
    location2 / W / mM

