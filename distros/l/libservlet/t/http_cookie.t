# -*- Mode: Perl; indent-tabs-mode: nil; -*-

use lib "./t";
use strict;
use warnings;

use Test;

BEGIN { plan tests => 21 }

use Servlet::Http::Cookie ();

ok(my $cookie = Servlet::Http::Cookie->new("test"));

# bad cookie names
eval { my $cookie2 = Servlet::Http::Cookie->new() };
ok($@);
eval { my $cookie3 = Servlet::Http::Cookie->new(0x00) };
ok($@);
eval { my $cookie4 = Servlet::Http::Cookie->new('name with spaces' ) };
ok($@);
eval { my $cookie5 = Servlet::Http::Cookie->new('$beginswith') };
ok($@);
eval { my $cookie5 = Servlet::Http::Cookie->new('secure') };
ok($@);

ok($cookie->getComment(), undef);
$cookie->setComment("hi there");
ok($cookie->getComment(), "hi there");

ok($cookie->getDomain(), undef);
$cookie->setDomain("LocalHost");
ok($cookie->getDomain(), "localhost");

ok($cookie->getMaxAge(), -1);
$cookie->setMaxAge(300);
ok($cookie->getMaxAge(), 300);

ok($cookie->getName(), "test");

ok($cookie->getPath(), undef);
$cookie->setPath("/foo/bar");
ok($cookie->getPath(), "/foo/bar");

ok(!$cookie->getSecure());
$cookie->setSecure(1);
ok($cookie->getSecure);

ok($cookie->getValue(), undef);
$cookie->setValue("12345");
ok($cookie->getValue(), "12345");

ok($cookie->getVersion(), 0);
$cookie->setVersion(1);
ok($cookie->getVersion(), 1);

exit;
