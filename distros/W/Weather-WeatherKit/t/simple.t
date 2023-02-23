use Test2::V0;

use HTTP::Response;
use LWP::UserAgent;
use Weather::WeatherKit;

use File::Temp qw/tempfile/;

my %params = (
    team_id    => "XXXXXXXXXX",
    service_id => "com.domain.app",
    key_id     => "QX0X0X00XX",
);

my $key = '-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgYirTZSx+5O8Y6tlG
cka6W6btJiocdrdolfcukSoTEk+hRANCAAQkvPNu7Pa1GcsWU4v7ptNfqCJVq8Cx
zo0MUVPQgwJ3aJtNM1QMOQUayCrRwfklg+D/rFSUwEUqtZh7fJDiFqz3
-----END PRIVATE KEY-----';

my $weather = Weather::WeatherKit->new(%params, key => $key);

subtest 'jwt' => sub {
    my $jwt = $weather->jwt();

    like($jwt, qr/^ey.*/, 'JWT of expected form');

    my %opt = (
        iat => time(),
        exp => time()+3600
    );
    my $jwt2 = $weather->jwt(%opt);

    isnt($jwt, $jwt2, 'Different JWT');
    like($jwt2, qr/^ey.*/, 'Still of expected form');
};

my $base = "https://weatherkit.apple.com/api/v1/weather";
my %opt  = (
    lat => 1,
    lon => 2,
    language => 'en_US'
);

subtest '_weather_url' => sub {
    is(Weather::WeatherKit::_weather_url(%opt), "$base/en_US/1/2", "Correct URL");
    is(
        Weather::WeatherKit::_weather_url(%opt, dataSets => 'currentWeather'),
        "$base/en_US/1/2?dataSets=currentWeather",
        "Correct Query param"
    );
};

my $content = '{"currentWeather":{"version":1}}';
my $mock    = Test2::Mock->new(
    class => 'LWP::UserAgent',
    track => 1,
    override => [
        get => sub { return HTTP::Response->new(200, 'SUCCESS', undef, $content) },
    ],
);

subtest 'get' => sub {
    my $out = $weather->get(%opt);
    my $jwt = $weather->jwt;

    is($out, $content, 'Received response');

    is(
        $mock->call_tracking->[0]->{args},
        array {
            item object {prop blessed => 'LWP::UserAgent'; etc};
            item "$base/en_US/1/2";
            item 'Authorization';
            item "Bearer $jwt";
            end
        },
        'get call correct'
    );
};

subtest 'Optional parameters' => sub {
    my ($fh, $filename) = tempfile();
    print $fh $key;
    close $fh;
    my $ua = LWP::UserAgent->new();

    $weather = Weather::WeatherKit->new(
        %params,
        key_file   => $filename,
        language   => 'en_GB',
        timeout    => 10,
        expiration => 1000,
        ua         => $ua
    );
    my %out = $weather->get(lat => -1, lon => 0);
    my $jwt = $weather->jwt;

    is(\%out, {currentWeather=>{version=>1}}, 'Received JSON response');

    is(
        $mock->call_tracking->[1]->{args},
        array {
            item $ua;
            item "$base/en_GB/-1/0";
            item 'Authorization';
            item "Bearer $jwt";
            end
        },
        'get call correct'
    );
};

done_testing;
