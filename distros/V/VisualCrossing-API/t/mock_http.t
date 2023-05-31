use Test::More tests => 6;

use strict;
use VisualCrossing::API;
use Test::Exception;
use Test::More;
use Test::MockModule;

my $key = "K1234";
my $location = "AU419";
my $date = "";

my $forecast;
{
    my $mock = Test::MockModule->new('HTTP::Tiny');
    my $fileName = "t/current.json";
    open my $fh, '<', $fileName || die "WARN: Couldn't read from $fileName\n";
    my $file_content = do { local $/; <$fh> };
    close $fh;

    $mock->mock(
        "get" => sub {
            my ($self, $url) = @_;
            return {
                url     => $url,
                success => 1,
                status  => 200,
                content => $file_content,
                headers => {
                    'content-type'   => 'application/json',
                    'content-length' => length $file_content,
                }
            };
        }
    );

    my $weatherApi = VisualCrossing::API->new(
        key      => $key,
        location => $location,
        date     => $date,
        include  => "current"
    );
    $forecast = $weatherApi->getWeather;
}


ok($forecast);
is($forecast->{downloaded}, "into test dir");
is(sprintf("%.4f", $forecast->{latitude}), "42.4738");
is($forecast->{currentConditions}->{datetime}, "12:00:00");
is($forecast->{currentConditions}->{conditions}, "Partially cloudy");
is(sprintf("%.1f", $forecast->{currentConditions}->{feelslike}), "78.0");
