use strict;
use Test::More;
use HTTP::Request;
use HTTP::Message::PSGI;
use URI::QueryParam;

BEGIN { use_ok 'WWW::GoogleAnalytics::Mobile' }

my $gam = WWW::GoogleAnalytics::Mobile->new(
    base_url => '/t',
    account => 'UA-99999-9',
    secret => 'very secret '
);

my $req = HTTP::Request->new(GET => 'http://example.com/foo/bar?baz=987');
$req->referer("http://example.com/ref/page?guid=XXXXX&category=321");

my $url = $gam->image_url($req->to_psgi);
ok($url);
isa_ok($url, 'URI');

is( $url->query_param('utmac'), 'UA-99999-9');
like( $url->query_param('utmn'), qr/^\d+$/);
is( $url->query_param('utmhn'), 'example.com');
like( $url->query_param('utmr'), qr!http://example\.com/ref/page! );
unlike( $url->query_param('utmr'), qr!guid=! );
like( $url->query_param('utmr'), qr!category=! );
is( $url->query_param('utmp'), '/foo/bar?baz=987');
like( $url->query_param('cs'), qr/\w{6}/);
is( $url->query_param('guid'), 'ON');

done_testing();

