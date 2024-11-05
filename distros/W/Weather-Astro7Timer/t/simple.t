use Test2::V0;

use HTTP::Response;
use LWP::UserAgent;
use Weather::Astro7Timer;

my $base = "www.7timer.info/bin";
my %opt = (
    lat     => 1,
    lon     => 2,
    lang    => 'en',
    product => 'astro'
);

subtest '_weather_url' => sub {
    my $weather = Weather::Astro7Timer->new();
    my $url     = $weather->_weather_url(%opt);
    like($url, qr#$base/astro.php\?.*#, 'Correct base URL');

    my %params = $url =~ /(?:\?|&|;)([^=]+)=([^&|;]+)/g;
    is({%params, product => 'astro'}, {%opt});
};

my $content = '{"product":"astro"}';
my $mock    = Test2::Mock->new(
    class    => 'LWP::UserAgent',
    track    => 1,
    override => [
        get =>
            sub {return HTTP::Response->new(200, 'SUCCESS', undef, $content)},
    ],
);

subtest 'get' => sub {
    my $weather = Weather::Astro7Timer->new();
    my $out     = $weather->get(%opt);
    my %out     = $weather->get(%opt);

    is($out, $content, 'Received response');
    is(\%out, {product => 'astro'}, 'JSON output');
};

subtest 'Optional parameters' => sub {
    my $weather = Weather::Astro7Timer->new();
    my $out     = $weather->get(%opt);

    like($weather->{ua}->agent, qr/^libwww-perl Weather::Astro7Timer/, 'Default agent');

    my $ua = LWP::UserAgent->new(max_redirect => 11, agent => 'test', timeout => 12);

    $weather = Weather::Astro7Timer->new(
        timeout => 9,
        ua      => $ua
    );
    $out = $weather->get(%opt);

    is($weather->{ua}->max_redirect, 11, 'Max redirect from the custom ua');
    is($weather->{ua}->timeout, 12, 'Timeout ignored');
    is($weather->{ua}->agent, 'test', 'Agent set');

    $weather = Weather::Astro7Timer->new(
        timeout => 9,
    );
    $out = $weather->get(%opt);
    is($weather->{ua}->timeout, 9, 'Timeout set');
};

$content = '<product name="astro"></product>';
$mock->override(
    get => sub {return HTTP::Response->new(200, 'SUCCESS', undef, $content)});

subtest 'init_to_ts' => sub {
    is(Weather::Astro7Timer::init_to_ts('2023032606'), 1679810400, 'TS OK');
    is(Weather::Astro7Timer::init_to_ts('20230326'), (), 'TS NOT OK');
};

subtest 'get xml / internal / png' => sub {
    my $weather = Weather::Astro7Timer->new();
    my %out     = $weather->get(%opt, output => 'internal');
    if (eval "require XML::Simple;") {
        my %out2 = $weather->get(%opt, output => 'xml');
        is(\%out2, {name => 'astro'}, 'XML output');
    }
    my %out3 = $weather->get(%opt, output => 'png');
    is(\%out,  {data => $content}, 'Internal output');
    is(\%out3, {data => $content}, 'Png output in hash');
    my $out4 = $weather->get(%opt, output => 'png');
    is($out4, $content, 'Png output');
};

done_testing;
