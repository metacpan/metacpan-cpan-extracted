use utf8;
use Test::More;
use WebService::Yamli;
use Test::RequiresInternet ('yamli.com' => 80);
plan tests => 4;
diag "Online check possible";

my $tr = WebService::Yamli::tr('7aga');
is $tr, 'حاجة';

my @tr = WebService::Yamli::tr('7aga');
is $tr[0], 'حاجة';
isnt scalar @tr, 1;

my $words = WebService::Yamli::tr('7aga 7aga');
is $words, 'حاجة حاجة';
