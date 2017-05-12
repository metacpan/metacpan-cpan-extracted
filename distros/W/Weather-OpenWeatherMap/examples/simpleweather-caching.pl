use strictures 1;

use Weather::OpenWeatherMap;

my $location = shift @ARGV || die "No location specified\n";
my $api_key  = shift @ARGV;
warn "Attempting to continue without API key" unless $api_key;

my $result = 
  Weather::OpenWeatherMap->new( 
    cache => 1,
    cache_dir => 'cache',
    ( $api_key ? (api_key => $api_key) : () ),
  )->get_weather( location => $location );

die "Error: ".$result->error unless $result->is_success;

my $place = $result->name;
my $temp  = $result->temp_f;
my $wind  = $result->wind_speed_mph;
my $direc = $result->wind_direction;

print "$place -> ${temp}F wind ${wind}mph $direc\n"
