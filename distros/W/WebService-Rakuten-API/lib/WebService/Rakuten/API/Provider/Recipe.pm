package WebService::Rakuten::API::Provider::Recipe;
use strict;
use warnings;

use constant BASERECIPEURL => 'https://app.rakuten.co.jp/services/api/Recipe/CategoryList/20121121?';

use constant CategoryRanking => 'https://app.rakuten.co.jp/services/api/Recipe/CategoryRanking/20121121?';

sub call{
 my($class,$context,$arg) = @_;
 my $url = URI->new(BASERECIPEURL);
 $url->query_form(applicationId => $context->appid,categoryType=>$arg->{categoryType});
 my $res = $context->furl->get($url);
}

1;
