use strict;
use warnings;
use utf8;

use Test::More tests => 21;
use Test::More::UTF8;

use Weather::TW::Forecast;

foreach my $place (Weather::TW::Forecast->all_locations){
  my $w = Weather::TW::Forecast->new(location => $place);
  my @forecasts = $w->short_forecasts;
  is scalar(@forecasts), 3, "three short forecasts in $place";
  # if the value in forecasts is empty, it will croak
  # so no need to fetch and parse again to varify them
}
