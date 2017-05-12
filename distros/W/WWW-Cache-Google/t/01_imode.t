use strict;
use Test;
BEGIN { plan tests => 4 }

use WWW::Cache::Google::Imode;
use URI;

my %test = qw(
	http://www.yahoo.com/
	http://wmlproxy.google.com/chtmltrans/p=i/s=0/u=www.yahoo.com@2F/c=0
	http://www.yahoo.com/search?foo=bar&baz=hoge
	http://wmlproxy.google.com/chtmltrans/p=i/s=0/u=www.yahoo.com@2Fsearch@3Ffoo@3Dbar@26baz@3Dhoge/c=0
);

while (my($orig, $cache) = each %test) {
	my $c = WWW::Cache::Google::Imode->new($orig);
	ok($c->as_string, $cache);
	my $cu = WWW::Cache::Google::Imode->new(URI->new($orig));
	ok($cu->as_string, $cache);
}
