#!perl
package main;
use strict;
use Weather::MOSMIX;
use Data::Dumper;
use charnames ':full';
use Weather::MOSMIX;
use Time::Piece;
use Getopt::Long;

our $VERSION = '0.01';

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
    $w->forecast(latitude => $latitude, longitude => $longitude );
my $out = $w->format_forecast( $f );

binmode STDOUT, ':encoding(UTF-8)';

for my $day ('today', 'tomorrow') {
    my $issue = substr $out->{issuetime},0,10;
    my $date = $out->{weather}->{$day}->{date}->strftime('%Y-%m-%d');
    print "$out->{location} (\x{1F321}$Weather::MOSMIX::Weathercodes::as_emoji $out->{weather}->{$day}->{min}/$out->{weather}->{$day}->{max}) ($date)\n";
    for my $w (@{ $out->{weather}->{$day}->{weather}}) {
        print $w->{timestamp}, "\n";
        print sprintf "%02d %s$Weather::MOSMIX::Weathercodes::as_emoji %s\n", $w->{timestamp}->hour, $w->{description}->{emoji}, $w->{description}->{text};
    };

    # Maybe a one-line information per day, with samples/aggregates at
    # 03, 09, 15 and 21 ?
};

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

