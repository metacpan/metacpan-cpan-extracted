
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Weather/OpenWeatherMap.pm',
    'lib/Weather/OpenWeatherMap/Cache.pm',
    'lib/Weather/OpenWeatherMap/Error.pm',
    'lib/Weather/OpenWeatherMap/Request.pm',
    'lib/Weather/OpenWeatherMap/Request/Current.pm',
    'lib/Weather/OpenWeatherMap/Request/Find.pm',
    'lib/Weather/OpenWeatherMap/Request/Forecast.pm',
    'lib/Weather/OpenWeatherMap/Result.pm',
    'lib/Weather/OpenWeatherMap/Result/Current.pm',
    'lib/Weather/OpenWeatherMap/Result/Find.pm',
    'lib/Weather/OpenWeatherMap/Result/Forecast.pm',
    'lib/Weather/OpenWeatherMap/Result/Forecast/Block.pm',
    'lib/Weather/OpenWeatherMap/Result/Forecast/Day.pm',
    'lib/Weather/OpenWeatherMap/Result/Forecast/Hour.pm',
    'lib/Weather/OpenWeatherMap/Test.pm',
    'lib/Weather/OpenWeatherMap/Units.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/cache.t',
    't/error.t',
    't/inc/Testing/Error.pm',
    't/inc/Testing/OpenWeatherMap.pm',
    't/inc/Testing/Request.pm',
    't/inc/Testing/Request/Current.pm',
    't/inc/Testing/Request/Find.pm',
    't/inc/Testing/Request/Forecast.pm',
    't/inc/Testing/Result.pm',
    't/inc/Testing/Result/Cachable.pm',
    't/inc/Testing/Result/Current.pm',
    't/inc/Testing/Result/Find.pm',
    't/inc/Testing/Result/Forecast/Daily.pm',
    't/inc/Testing/Result/Forecast/Hourly.pm',
    't/openweathermap.t',
    't/release-cpan-changes.t',
    't/release-dist-manifest.t',
    't/release-pod-linkcheck.t',
    't/release-synopsis.t',
    't/release-unused-vars.t',
    't/request/current.t',
    't/request/find.t',
    't/request/forecast/daily.t',
    't/request/forecast/hourly.t',
    't/result/current.t',
    't/result/find.t',
    't/result/forecast/daily.t',
    't/result/forecast/hourly.t',
    't/units.t'
);

notabs_ok($_) foreach @files;
done_testing;
