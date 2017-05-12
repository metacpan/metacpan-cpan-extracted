package WebService::Rakuten::API::Provider::Ichiba;
use strict;
use warnings;

use constant BASEICHIBAURL => 'https://app.rakuten.co.jp/services/api/IchibaItem/Search/20140222?';

use constant BASEICHIBAGENRE => 'https://app.rakuten.co.jp/services/api/IchibaGenre/Search/20140222?';

use constant BASETAGURL => 'https://app.rakuten.co.jp/services/api/IchibaTag/Search/20140222?';

use constant BASERANKURL => 'https://app.rakuten.co.jp/services/api/IchibaItem/Ranking/20120927?';

sub call{
 my($class,$context,$arg) = @_;
 my $url = URI->new(BASEICHIBAURL);
 $url->query_form(applicationId => $context->appid,format=>$arg->{format},keyword =>$arg->{keyword});
 my $res = $context->furl->get($url);
 my $response = JSON::decode_json($res->decoded_content);
}

1;
