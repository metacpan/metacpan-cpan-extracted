use Test::More tests => 11;

use strict;
use warnings;
use Test::MockModule;
use JSON::XS;

my $key = "K1234";
my $location = "L123";
my $date = "2023-05-25";

my $weatherApi;
my $forecast;
{
    my $fileName = "t/current.json";
    my $coder = JSON::XS->new->utf8->canonical;
    open my $fh, '<', $fileName || die "WARN: Couldn't read from $fileName\n";
    my $file_content = do { local $/; <$fh> };
    $forecast = $coder->decode($file_content);
    close $fh;

    my $mock = Test::MockModule->new('VisualCrossing::API');
    $mock->mock(
        "getWeather" => sub {
            return $forecast;
        }
    );

    $weatherApi = VisualCrossing::API->new(
        key      => $key,
        location => $location,
        date     => $date,
        date2     => $date,
        include  => "current"
    );
    $forecast = $weatherApi->getWeather;
}

ok($weatherApi);
is($weatherApi->url, "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/L123/2023-05-25/2023-05-25?key=K1234&include=current");
ok($forecast);
is($forecast->{downloaded}, "into test dir");
is(sprintf("%.4f", $forecast->{latitude}), "42.4738");
is(sprintf("%.4f", $forecast->{longitude}), "-83.5505");
is($forecast->{currentConditions}->{datetime}, "12:00:00");
is($forecast->{currentConditions}->{conditions}, "Partially cloudy");
is(sprintf("%.1f", $forecast->{currentConditions}->{feelslike}), "78.0");
is(sprintf("%.1f", $forecast->{currentConditions}->{temp}), "78.0");
is(sprintf("%.1f", $forecast->{currentConditions}->{humidity}), "37.9");
