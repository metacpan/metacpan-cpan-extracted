use strict;
use warnings;
use Test::More;
use URI::XS qw/uri :const/;

my ($uri);

$uri = uri('lalala');
is(ref($uri), 'URI::XS');

$uri = uri('//crazypanda.ru/abc');
is(ref($uri), 'URI::XS');

my @supported = qw/http https ftp socks/;

# check strict classes
foreach my $schema (@supported) {
    $uri = uri("$schema://crazypanda.ru/a/b/c");
    is(ref($uri), "URI::XS::$schema");
}

# same scheme assignable
$uri = uri("http://a.b");
$uri->assign("http://b.c/d");
is($uri->host, 'b.c');
is($uri->path, '/d');

# friend scheme assignable
$uri->assign("https://d.e"); # http can hold https
is($uri->scheme, 'https');
is($uri->host, 'd.e');
$uri->scheme('http');
is($uri, 'http://d.e');

ok(!eval {$uri->assign("ftp://ru.ru"); 1}); # wrong scheme via assign

$uri = uri("https://a.b");
$uri->assign("https://b.c/d");
is($uri->host, 'b.c');
is($uri->path, '/d');
ok(!eval {$uri->url("http://ru.ru"); 1}); # wrong scheme via url

$uri = uri('ftp://syber:pass@a.b');
is($uri->user, 'syber');
is($uri->password, 'pass');
ok(!eval {$uri->scheme("https"); 1}); # wrong scheme via scheme

# copy assign (set)
$uri = uri("http://a.b");
$uri->set(uri("http://c.d"));
is($uri->host, 'c.d');
$uri->set(URI::XS->new("https://e.f"));
is($uri->host, 'e.f');

ok(!eval {$uri->set(URI::XS->new("ftp://e.f")); 1});

$uri = uri("http://a.b");
ok(!eval {$uri->set(uri("ftp://e.f")); 1});

# create strict class
$uri = URI::XS::ftp->new('ftp://syber:pass@a.b');
is($uri->scheme, 'ftp');
is($uri->user, 'syber');
is($uri->password, 'pass');

ok(!eval {URI::XS::ftp->new('http://syber.ru'); 1});
ok(!eval {URI::XS::http->new('ftp://syber.ru'); 1});
ok(!eval {URI::XS::https->new('http://syber.ru'); 1});
$uri = URI::XS::http->new('https://syber.ru');
is($uri->scheme, 'https');

# apply strict scheme to proto-relative urls
$uri = URI::XS::http->new("//syber.ru");
is($uri, 'http://syber.ru');
$uri = URI::XS::https->new("//syber.ru");
is($uri, 'https://syber.ru');
$uri = URI::XS::ftp->new("syber.ru/abc", ALLOW_LEADING_AUTHORITY);
is($uri, 'ftp://syber.ru/abc');
# check other constructor syntax of custom schemas
$uri = URI::XS::http->new("//syber.ru", 'a=b');
is($uri, 'http://syber.ru?a=b');
$uri = URI::XS::https->new("//syber.ru", a => 1, b => 2);
is($uri, 'https://syber.ru?a=1&b=2');

done_testing();
