use utf8;
use Test::Needs 'LWP::Protocol::https';
use Test::RequiresInternet ('yamli.com' => 443);
use Test::More;

use WebService::Yamli;

plan tests => 1;
diag "Online check possible";

$WebService::Yamli::HTTPS = 1;

my $tr = WebService::Yamli::tr('7aga');
is $tr, 'حاجة';
