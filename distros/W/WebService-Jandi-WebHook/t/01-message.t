use utf8;
use strict;
use warnings;
use open ':std', ':encoding(utf8)';
use Test::More tests => 1;

use Try::Tiny;
use WebService::Jandi::WebHook;

my $url = $ENV{WEBSERVICE_JANDI_WEBHOOK_URL};

my $jandi = WebService::Jandi::WebHook->new($url);

SKIP: {
    skip 'WEBSERVICE_JANDI_WEBHOOK_URL is required', 1 unless $url;
    my $jandi = WebService::Jandi::WebHook->new($url);
    my $res   = $jandi->request('안녕하세요');
    ok( $res->{success} );
}
