use Test2::V0;
use Test2::Tools::Warnings qw/warning/;

use HTTP::Response;
use LWP::UserAgent;
use Weather::API::Base ':all';

my $base = Weather::API::Base->new();

subtest 'constructor' => sub {
    my %defaults = (
        scheme  => 'https',
        timeout => 30,
        agent   => "libwww-perl Weather::API::Base/".$Weather::API::Base::VERSION,
        units   => 'metric',
        error   => 'return',
    );

    is($base->{$_}, $defaults{$_}, "Default $_") for keys %defaults;

    my $ua = LWP::UserAgent->new();
    $ua->agent('custom');   

    my $custom_ua = Weather::API::Base->new(ua => $ua, scheme => 'http');
    is($custom_ua->{agent}, 'custom', 'Override agent');

    {
        package Weather::Child;
        use parent 'Weather::API::Base';
        our $VERSION = 6.66;
        sub new {
            my ($class, %args) = @_;
            my $self           = $class->SUPER::new(language => 'en_US', %args);

            return $self;
        }
        1;
    }

    my $child = Weather::Child->new();
    like($child->{agent}, qr/Weather::Child.6.66/, 'Child agent');
    is($child->{language}, 'en_US', 'language set');
};

subtest '_get_output' => sub {
    my $content = '{"main":{"temp":29.48}}';
    my $resp    = HTTP::Response->new(200, 'SUCCESS', undef, $content);
    is($base->_get_output($resp), $content, "Got string output");

    $base->{output} = 'json';
    is(
        {$base->_get_output($resp, 1)},
        {main => {temp => 29.48}},
        "Got decoded JSON output"
    );
    is($base->_get_output($resp), $content, "Got string output");

    $base->{output} = 'png';
    is({$base->_get_output($resp, 1)}, {data => $content}, "Other output");

    $resp = HTTP::Response->new(401, 'Unauthorized', undef, '{}');
    is(
        {$base->_get_output($resp, 1)},
        {error => $resp},
        "Error response in hash"
    );
    is($base->_get_output($resp), 'ERROR: 401 Unauthorized', "Error in string");

    $base->{error} = '';
    $content = '<product name="astro"></product>';
    $resp    = HTTP::Response->new(200, 'SUCCESS', undef, $content);
    $base->{output} = 'xml';
    if (eval "require XML::Simple;") {
        is({$base->_get_output($resp, 1)}, {name => 'astro'}, "XML output");
        $base->{curl} = 1;
        is({$base->_get_output($content, 1)}, {name => 'astro'}, "XML for curl");
    }
};


subtest 'ts_to_date' => sub {
    is(ts_to_date(1000000, 1), '1970-01-12 13:46:40Z', 'UTC Date OK');
    like(ts_to_date(1000000), qr/1970-01-1\d \d\d:\d\d:40/, 'Date OK');
};

subtest 'ts_to_iso_date' => sub {
    is(ts_to_iso_date(1000000, 1), '1970-01-12T13:46:40Z', 'UTC Date OK');
    like(ts_to_iso_date(1000000), qr/1970-01-1\dT\d\d:\d\d:40/, 'Date OK');
};

subtest 'datetime_to_ts' => sub {
    is(datetime_to_ts('1970-01-12 13:46:40Z'), 1000000, 'Date OK');
    is(datetime_to_ts('1970-01-12 13:46:40', 1), 1000000, 'Date OK');
    ok(abs(datetime_to_ts('1970-01-12 13:46:40')-1000000) < 13*3600, 'Local date');
};

subtest 'convert_units' => sub {
    my @tests = (
        ['mph','km/h',10,16.09344],
        ['m/s','m/s',10,10],
        ['Bft','m/s',10,26.44],
        ['m/s','Bft',10,5.23],
        ['kt','km/h',10,18.52],
        ['in','mm',10,254],
        ['mm','km',10,10/1000000],
        ['kt','km/h',10,18.52],
        ['mi','m',10,16093.44],
        ['mbar','mmHg',10,7.5],
        ['atm','kPa',10,1013.25],
        ['kPa','hPa',10,100],
        ['K','C',10,-263.15],
        ['C','K',0,273.15],
        ['C','F',0,32],
        ['F','C',212,100],
    );
    foreach (@tests) {
        my $res = pop @{$_};
        is(convert_units(@{$_}), float($res, tolerance => 0.01), "Convert $_->[2] $_->[0] to $_->[1]");
    }
};

subtest '_get_ua' => sub {
    my ($content, $request);
    my $mock = Test2::Mock->new(
        class    => 'LWP::UserAgent',
        override => [
            get => sub {
                my $req = $_[1];
                compare_requests($req, $$request);
                return HTTP::Response->new(200, 'SUCCESS', undef, $$content);
            },
        ],
    );

    my $base = Weather::API::Base->new();
    my $api  = "api.weather.com";
    $request = \"https://$api";
    my $resp = $base->_get_ua($api);
    is($resp->status_line, '200 SUCCESS', 'Response OK');

    $api  = "http://api.weather.com";
    $request = \$api;
    $resp = $base->_get_ua($api);
    is($resp->status_line, '200 SUCCESS', 'Response OK');

    $base->{debug} = 1;
    is(warning { $base->_get_ua($api) }, "$$request\n", "Got expected warning");
};

subtest '_deref' => sub {
    is(Weather::API::Base::_deref(1), 1, "Not ref");
    is({Weather::API::Base::_deref({a=>1})}, {a=>1}, "Hash");
    is([Weather::API::Base::_deref([1])], [1], "Array");
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
