use strict;
use warnings;
use utf8;

use Test::More tests => 21;
use Test::More::UTF8;

use Weather::TW::Forecast;

foreach my $place (Weather::TW::Forecast->all_locations){
  my $w = Weather::TW::Forecast->new(location => $place);
  my @weekly = $w->weekly_forecasts;
  is scalar(@weekly), 7, "Seven weely forecasts in $place";
  # if the value in weely is empty, it will croak
  # so no need to fetch and parse again to varify them
}
