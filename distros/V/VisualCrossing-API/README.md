## VisualCrossing.net Wrapper

This is a wrapper for the visualcrossing.com API. You need an API key to
use it (https://www.visualcrossing.com/weather/weather-data-services#). Please consult the API docs at https://www.visualcrossing.com/resources/documentation/weather-api/timeline-weather-api/.

## Example Use

```perl
use VisualCrossing::API;
use Data::Dumper;

my $location = "AU419";
my $date = "2023-05-25"; # example date (optional)
my $key = "ABCDEFGABCDEFGABCDEFGABCD"; # example VisualCrossing API key

## Current Data (limit to current, saves on API cost)
my $weatherApi = VisualCrossing::API->new(
    key       => $key,
    location => $location,
    include  => "current",
);
my $current = $weatherApi->getWeather;

say "current temperature: " . $current->{currentConditions}->{temp};
say "current conditions: " . $current->{currentConditions}->{conditions};

## Historical Data (limit to single day, saves on API cost)
my $weatherApi = VisualCrossing::API->new(
    key       => $key,
    location => $location,
    date      => $date
    date2      => $date
    include  => "days",
);
my $history = $weatherApi->getWeather;

say "$date temperature: " . $history->{days}[0]->{temp};
say "$date conditions: " . $history->{days}[0]->{conditions};
```

### Key (required)

The "key" string is your VisualCrossing API key. You can get one at https://www.visualcrossing.com/weather-data-editions
The free tier allows for 1000 records per day.

### Location (required)

The "location" string, can be a location ID, a city name, or a lat/long pair.

If passing a lat/long pair, it can be in the form of "lat,long" (no spaces).
It could also be passed as keys "latitude" and "longitude".

### Dates  (optional)

The "date" string can be a date in the form of "YYYY-MM-DD", "YYYY-MM-DDTHH:MM:SS", UNIX format of seconds since the 1970.

It can also be a period "2020-10-01/2020-12-31". The second date could also be passed in the "date2" key.
or a Dynamic period Request like: “last30days”, “today”, “yesterday”, and “lastyear”.  

The date is optional, and if not passed, the request will retrieve the forecast at the requested location for the next 15 days.

## Build, release

Ensure you have Dist::Zilla installed, and that it is in your path. 
For example:

```bash
cpan install Dist::Zilla
cpan Dist::Zilla Mouse
PATH=$PATH:/opt/homebrew/Cellar/perl/5.36.1/bin
```

Then run the following commands to build, test, install, clean, and release:

```sh
dzil clean
dzil build
dzil test
dzil install
dzil clean
dzil release
```

## Links

Patches/suggestions welcome

Github: https://github.com/duanemay/VisualCrossing-API

Based on the good work of: Martin-Louis Bright https://github.com/mlbright/DarkSky-API
