use Test::More tests => 11;

use strict;
use warnings;
use Test::MockModule;
use JSON::XS;

my $key = "K1234";
my $location = "AU419";
my $date = "2023-05-25";

my $forecast;
{
    my $fileName = "t/historic.json";
    my $coder = JSON::XS->new->utf8->canonical;
    open my $fh, '<', $fileName || die "WARN: Couldn't read from $fileName\n";
    my $file_content = do {
        local $/;
        <$fh>
    };
    $forecast = $coder->decode($file_content);
    close $fh;

    my $mock = Test::MockModule->new('VisualCrossing::API');
    $mock->mock(
        "getWeather" => sub {
            return $forecast;
        }
    );

    my $weatherApi = VisualCrossing::API->new(
        key      => $key,
        location => $location,
        date     => $date,
        date2    => $date,
        include  => "days"
    );
    $forecast = $weatherApi->getWeather;

}

ok($forecast);
is($forecast->{downloaded}, "into test dir");
is(sprintf("%.4f", $forecast->{latitude}), "42.4738");
is(sprintf("%.4f", $forecast->{longitude}), "-83.5505");
is($forecast->{days}[0]->{datetime}, "2023-05-25");
is($forecast->{days}[0]->{conditions}, "Clear");
is(sprintf("%.1f", $forecast->{days}[0]->{feelslike}), "49.0");
is(sprintf("%.1f", $forecast->{days}[0]->{tempmin}), "40.0");
is(sprintf("%.1f", $forecast->{days}[0]->{tempmax}), "63.9");
is(sprintf("%.1f", $forecast->{days}[0]->{temp}), "51.4");
is(sprintf("%.1f", $forecast->{days}[0]->{humidity}), "48.5");
