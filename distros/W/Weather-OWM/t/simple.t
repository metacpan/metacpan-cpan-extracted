use Test2::V0;

use HTTP::Response;
use LWP::UserAgent;
use Weather::OWM;

my $owm = Weather::OWM->new(key => 'APIKEY');

my $request;
my $content;
my $mock = Test2::Mock->new(
    class    => 'LWP::UserAgent',
    track    => 1,
    override => [
        get => sub {
            my $req = $_[1];
            compare_requests($req, $$request);
            return HTTP::Response->new(200, 'SUCCESS', undef, $$content);
        },
    ],
);

subtest 'constructor' => sub {
    my %defaults = (
        scheme  => 'https',
        timeout => 30,
        agent   => "libwww-perl Weather::OWM/".$Weather::OWM::VERSION,
        lang    => "en",
        units   => 'metric',
        error   => 'return',
    );

    is($owm->{$_}, $defaults{$_}, 'Default $_') for keys %defaults;

    my $ua = LWP::UserAgent->new();
    $ua->agent('custom');   

    my $custom_ua = Weather::OWM->new(key => 'APIKEY', ua => $ua);
    is($custom_ua->{agent}, 'custom', 'Override agent');
};

subtest 'get_weather' => sub {
    $content = \'<current>
    <temperature value="298.48" unit="kelvin"/>
    </current>';

    $request = \"https://api.openweathermap.org/data/2.5/weather?q=Zocca&appid=APIKEY&mode=xml";
    my %re = $owm->get_weather(loc => "Zocca", mode => 'xml', units => 'standard');

    is(
        \%re,
        {
            temperature => {
                value => 298.48,
                unit  => 'kelvin',
            }
        },
        'Decoded XML content as expected'
    );

    $request = \"https://api.openweathermap.org/data/2.5/forecast?units=metric&lon=-1.83&lat=51.18&appid=APIKEY";
    $content = \'{"main":{"temp":29.48}}';
    my $re = $owm->get_weather(lat => 51.18, lon => -1.83, product => 'forecast');
    is($re, $$content, 'Content as expected');

    $request = \"https://pro.openweathermap.org/data/2.5/forecast/hourly?zip=10001&appid=APIKEY&lang=el&units=metric";
    %re = $owm->get_weather(zip => 10001, lang => 'el', product => 'hourly');
    is(\%re, {main=>{temp=>29.48}}, 'Decoded JSON content as expected');

    $request = \"https://api.openweathermap.org/data/2.5/forecast/daily?city_id=1&appid=APIKEY&mode=html";
    %re = $owm->get_weather(city_id=>1, mode => 'html', units => 'standard', product => 'daily');
    is(\%re, {data=>$$content}, 'Content not decoded as expected');

};

subtest 'get_weather_response' => sub {
    $request = \"https://api.openweathermap.org/data/2.5/forecast?units=metric&lon=-1.83&lat=51.18&appid=APIKEY";
    $content = \'{"main":{"temp":29.48}}';
    my $re = $owm->get_weather_response(lat => 51.18, lon => -1.83, product => 'forecast');
    is($re->decoded_content, $$content, 'Content as expected');
};

subtest 'one_call' => sub {
    $request = \'https://api.openweathermap.org/data/3.0/onecall?appid=APIKEY&lon=16.8&lat=15.6&units=imperial';
    $content = \'{"current":{"temp":38.1}}';
    my $re = $owm->one_call(lat => 15.6, lon => 16.8, units => 'imperial');
    is($re, $$content, 'Content as expected');
    $request = \'https://api.openweathermap.org/data/3.0/onecall/timemachine?appid=APIKEY&dt=1640995200&lon=16.8&lat=15.6';
    $re = $owm->one_call(lat => 15.6, lon => 16.8, units => 'standard', date=> '2022-01-01 00:00:00Z', product=>'historical');
    is($re, $$content, 'Content as expected');
    $request = \'https://api.openweathermap.org/data/3.0/onecall/day_summary?appid=APIKEY&date=2022-01-01&lon=16.8&lat=15.6';
    $re = $owm->one_call(lat => 15.6, lon => 16.8, units => 'standard', date=>'2022-01-01', product=>'daily');
    is($re, $$content, 'Content as expected');

};

subtest 'one_call_response' => sub {
    $request = \'https://api.openweathermap.org/data/3.0/onecall?appid=APIKEY&lon=16.8&lat=15.6&units=imperial';
    $content = \'{"current":{"temp":38.1}}';
    my $re = $owm->one_call_response(lat => 15.6, lon => 16.8, units => 'imperial');
    is($re->decoded_content, $$content, 'Content as expected');
};

subtest 'get_history' => sub {
    $request = \'https://history.openweathermap.org/data/2.5/history/city?cnt=72&q=Greenwich,UK&appid=APIKEY&start=1672531200&type=hour';
    $content = \'{"list":[{"main":{"temp":38.1}}]}';
    my $re = $owm->get_history(
        loc     => 'Greenwich,UK',
        start   => '2023-01-01 00:00:00Z',
        cnt     => '72'
    );
    is($re, $$content, 'Content as expected');

    $request = \'https://history.openweathermap.org/data/2.5/history/city?end=1672617600&q=Greenwich,UK&appid=APIKEY&start=1672531200&type=hour';
    $re = $owm->get_history(
        product => 'hourly',
        loc     => 'Greenwich,UK',
        start   => '2023-01-01 00:00:00Z',
        end     => '2023-01-02 00:00:00Z'
    );
    
    is($re, $$content, 'Content as expected');

    $request = \'https://history.openweathermap.org/data/2.5/aggregated/year?appid=APIKEY&city_id=1';
    $re = $owm->get_history(
        product => 'year',
        city_id => 1,
    );
    is($re, $$content, 'Content as expected');

    $request = \'https://history.openweathermap.org/data/2.5/aggregated/month?appid=APIKEY&city_id=1&month=1';
    $re = $owm->get_history(
        product => 'month',
        city_id => 1,
        month   => 1
    );
    is($re, $$content, 'Content as expected');

    $request = \'https://history.openweathermap.org/data/2.5/aggregated/day?appid=APIKEY&city_id=1&month=1&day=1';
    $re = $owm->get_history(
        product => 'day',
        city_id => 1,
        month   => 1,
        day     => 1
    );
    is($re, $$content, 'Content as expected');
};

subtest 'get_history_response' => sub {
    $request = \'https://history.openweathermap.org/data/2.5/history/city?cnt=72&q=Greenwich,UK&appid=APIKEY&start=1672531200&type=hour';
    $content = \'{"list":[{"main":{"temp":38.1}}]}';
    my $re = $owm->get_history_response(
        loc     => 'Greenwich,UK',
        start   => '2023-01-01 00:00:00Z',
        cnt     => '72'
    );
    is($re->decoded_content, $$content, 'Content as expected');
};

subtest 'geo' => sub {
    $request = \'https://api.openweathermap.org/geo/1.0/direct?appid=APIKEY&q=Portland,ME,US';
    $content = \'[{"lon":"-70.25","lat":"43.66"}]';
    my @locations = $owm->geo(city => 'Portland,ME,US');
    is(\@locations, [{lon => -70.25, lat => 43.66}], 'Content as expected');

    $request = \'https://api.openweathermap.org/geo/1.0/reverse?lat=43.65&appid=APIKEY&lon=-70.3';
    $content = \'[{"name":"Portland","state":"Maine","country":"US"}]';
    @locations = $owm->geo(lat => 43.65, lon => -70.3);
    is(\@locations, [{name=>"Portland",state=>"Maine",country=>"US"}], 'Content as expected');
};

subtest 'icon_url' => sub {
    is($owm->icon_url(), undef, 'Undef');
    is($owm->icon_url('10n'), 'https://openweathermap.org/img/wn/10n@2x.png', "Regular png");
    is($owm->icon_url('10n', 1), 'https://openweathermap.org/img/wn/10n.png', "Small png");
};

subtest 'icon_data' => sub {
    is($owm->icon_data(), undef, 'Undef');
    $request = \'"https://openweathermap.org/img/wn/$icon10d@2x.png';
    $content = \'data';
    is($owm->icon_data('10d'), $$content, "Donloaded png");
};

subtest 'error' => sub {
    $owm = Weather::OWM->new(key => 'APIKEY', scheme=>'http', units => 'standard');
    $mock = undef;
    my $errorresp = HTTP::Response->new(401, 'Unauthorized', undef, '{}');
    $mock = Test2::Mock->new(
        class    => 'LWP::UserAgent',
        track    => 1,
        override => [
            get => sub {
                my $req = $_[1];
                compare_requests($req, $$request);
                return $errorresp;
            },
        ],
    );

    $request = \"http://pro.openweathermap.org/data/2.5/forecast/climate?zip=10001&appid=APIKEY";
    my %re = $owm->get_weather(zip => 10001, product => 'climate');
    is(\%re, {error => $errorresp}, 'Error response as expected');

    $request = \"http://pro.openweathermap.org/data/2.5/forecast/hourly?zip=10001&appid=APIKEY";
    my $re = $owm->get_weather(zip => 10001, product => 'hourly');
    is($re, 'ERROR: 401 Unauthorized', 'Error response as expected');

};

subtest 'ts_to_date' => sub {
    is(Weather::OWM::ts_to_date(1000000, 1), '1970-01-12 13:46:40Z', 'Date OK');
};

done_testing;

sub compare_requests {
    my @parts1 = _break_request(shift);
    my @parts2 = _break_request(shift);
    is(\@parts1, \@parts2, 'Request as expected');
}

sub _break_request {
    my $req = shift;
    if ($req =~ /(https?)(:.*\?)(.*)/) {
        return $1, $2, sort(split /&/, $3);
    }
}
