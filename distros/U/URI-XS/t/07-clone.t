use strict;
use warnings;
use Test::More;
use URI::XS qw/uri :const/;

my $uri = URI::XS->new('http://mail.ru/catalog/?q1=v1&q2=v2&q3=v3#coolanchor');
my $p = new URI::XS("https://jopa.com/dfs/?a=b#ssss");
$p->query();
$p->set($uri);

ok($p eq 'http://mail.ru/catalog/?q1=v1&q2=v2&q3=v3#coolanchor');

my $cloned = $uri->clone;
is($cloned, 'http://mail.ru/catalog/?q1=v1&q2=v2&q3=v3#coolanchor');
$cloned->host('ya.ru');
is($cloned, 'http://ya.ru/catalog/?q1=v1&q2=v2&q3=v3#coolanchor');
is($uri, 'http://mail.ru/catalog/?q1=v1&q2=v2&q3=v3#coolanchor');

$uri = uri("http://ya.ru");
$cloned = $uri->clone;
is(ref($uri), 'URI::XS::http');
is(ref($cloned), 'URI::XS::http');

done_testing();
