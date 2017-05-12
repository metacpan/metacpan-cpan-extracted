use strict;
use Test::More;
use Test::TCP;

use Plack::Builder;
use Plack::Loader;
use Plack::Test;
use WWW::GoogleAnalytics::Mobile::PSGI;
use WWW::GoogleAnalytics::Mobile;
use HTTP::Request;
use HTTP::Message::PSGI;
use URI;
use URI::QueryParam;

my $server = Test::TCP->new(
    code => sub {
        my $port = shift;
        my $loader = Plack::Loader->load(
            'Standalone',
            host => '127.0.0.1',
            port => $port,
        );
        $loader->run(sub{ [200, [ 'Content-Type' => 'text/plain' ], [ shift->{REQUEST_URI} ]] });
    }
);

# For test
$WWW::GoogleAnalytics::Mobile::PSGI::GAM_UTM_GIF_LOCATION = 
    "http://127.0.0.1:".$server->port."/__utm.gif";
$WWW::GoogleAnalytics::Mobile::PSGI::DEBUG = 1;

my $beacon = WWW::GoogleAnalytics::Mobile::PSGI->new(
    secret => 'very secret',
);

ok($beacon);

my $app = builder {
    mount "/t" => $beacon;
};

my $gam = WWW::GoogleAnalytics::Mobile->new(
    base_url => '/t',
    account => 'UA-99999-9',
    secret => 'very secret'
);

my $req = HTTP::Request->new(GET => 'http://localhost/foo/bar?baz=987');
$req->referer("http://localhost/ref/page?guid=XXXXX&category=321");
my $gam_url = $gam->image_url($req->to_psgi);

test_psgi
    app => $app,
    client => sub {
          my $cb = shift;
          my $req = HTTP::Request->new(GET => $gam_url);
          my $res = $cb->($req);
          ok($res->is_success);
          is($res->header('X-GAM-Code'), '200');
          ok($res->header('X-GAM-URI'));

          my $url = eval {
              URI->new($res->header('X-GAM-URI'))
          };
          ok($url);
          is($url->host, '127.0.0.1');
          is($url->port, $server->port);

          is( $url->query_param('utmac'), 'UA-99999-9');
          like( $url->query_param('utmvid'), qr/^\w+$/);
          is( $url->query_param('utmhn'), 'localhost');
          like( $url->query_param('utmr'), qr!http://localhost/ref/page! );
          unlike( $url->query_param('utmr'), qr!guid=! );
          like( $url->query_param('utmr'), qr!category=! );
          is( $url->query_param('utmp'), '/foo/bar?baz=987');
          is( $url->query_param('utmip'), '127.0.0.0');
          ok( $url->query_param('utmwv'));
          ok( $url->query_param('utmcc'));

          like( $res->header('Set-Cookie'), qr/__utmmobile=\w+/ );;

    };

done_testing();


