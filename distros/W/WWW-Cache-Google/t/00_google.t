use strict;
use Test;
BEGIN { plan tests => 4 }

use WWW::Cache::Google;
use URI;

my %test = qw(
	http://www.yahoo.com/
	http://www.google.com/search?q=cache:www.yahoo.com%2F
	http://www.yahoo.com/search?foo=bar&baz=hoge
	http://www.google.com/search?q=cache:www.yahoo.com%2Fsearch%3Ffoo%3Dbar%26baz%3Dhoge
);

while (my($orig, $cache) = each %test) {
	my $c = WWW::Cache::Google->new($orig);
	ok($c->as_string, $cache);
	my $cu = WWW::Cache::Google->new(URI->new($orig));
	ok($cu->as_string, $cache);
}


    

