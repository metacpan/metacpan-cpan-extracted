use Test2::V0;

use HTTP::Response;
use LWP::UserAgent;
use Weather::Astro7Timer;

my $base = "://www.7timer.info/bin";
my %opt = (
    lat     => 1,
    lon     => 2,
    lang    => 'en',
    product => 'astro'
);

subtest '_weather_url - scheme' => sub {
    foreach (qw/http https/) {
        my $weather = Weather::Astro7Timer->new(scheme=>$_);
        my $url = $weather->_weather_url(%opt);
        like($url, qr#$_$base/astro.php\?.*#, 'Correct base URL');
        my %params = $url =~ /(?:\?|&|;)([^=]+)=([^&|;]+)/g;
        is({%params, product => 'astro'}, {%opt});
    }
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
    my $weather = Weather::Astro7Timer->new(scheme => $_);
    my $out     = $weather->get(%opt);
    my %out     = $weather->get(%opt);

    is($out, $content, 'Received response');
    is(\%out, {product => 'astro'}, 'JSON output');
};

subtest 'Optional parameters' => sub {
    my $weather = Weather::Astro7Timer->new();
    my $out     = $weather->get(%opt);

    like($weather->{ua}->agent, qr/^libwww-perl Weather::Astro7Timer/, 'Default agent');

    $weather = Weather::Astro7Timer->new(
        timeout => 9,
        agent   => 'test',
        ua      => LWP::UserAgent->new(max_redirect => 11)
    );
    $out = $weather->get(%opt);

    is($weather->{ua}->max_redirect, 11, 'Max redirect from the custom ua');
    is($weather->{ua}->timeout, 9, 'Timeout set');
    is($weather->{ua}->agent, 'test', 'Agent set');
};

$content = '<product name="astro"></product>';
$mock->override(
    get => sub {return HTTP::Response->new(200, 'SUCCESS', undef, $content)});

subtest 'get xml / internal / png' => sub {
    my $weather = Weather::Astro7Timer->new();
    my %out     = $weather->get(%opt, output => 'internal');
    my %out2    = $weather->get(%opt, output => 'xml');
    my %out3    = $weather->get(%opt, output => 'png');

    is(\%out, {data => $content}, 'Internal output');
    is(\%out2, {name => 'astro'}, 'XML output');
    is(\%out3, {data => $content}, 'Png output');
};

done_testing;
