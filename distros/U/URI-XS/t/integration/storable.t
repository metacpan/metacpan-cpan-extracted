use strict;
use warnings;
use Test::More;
use URI::XS qw/uri :const/;
use Storable qw/freeze thaw dclone/;

my $uri = URI::XS->new("http://ya.ru/path?a=b&c=d#jjj");
my $f = freeze($uri);
my $c = thaw($f);
is(ref($c), 'URI::XS');
is($c, "http://ya.ru/path?a=b&c=d#jjj");

$uri = uri("http://ya.ru/path?a=b&c=d#jjj");
$f = freeze($uri);
$c = thaw($f);
is(ref($c), 'URI::XS::http');
is($c, "http://ya.ru/path?a=b&c=d#jjj");
ok(!eval { $c->scheme('ftp'); 1});

$uri = uri("http://ya.ru/path?a=b&c=d#jjj");
$c = dclone($uri);
is(ref($c), 'URI::XS::http');
is($c, "http://ya.ru/path?a=b&c=d#jjj");
ok(!eval { $c->scheme('ftp'); 1});

done_testing();
