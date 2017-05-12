#!perl -w

use strict;
use Test::More tests => 6;


my $string = "http://thegestalt.org/simon/ foo bar.com http://someother.org/some/path/";

use_ok('URI::Find::Iterator');

my $it;
ok($it = URI::Find::Iterator->new($string), "create new");

my @uris = qw(http://thegestalt.org/simon/ http://someother.org/some/path/); 
while (my $match = $it->match()) {
	my $target = shift @uris;
	is($match, $target, "matched $target");
	ok($it->replace('http://twoshortplanks.com'),"do replace") if $match =~ /some/;
}

my $replaced = "http://thegestalt.org/simon/ foo bar.com http://twoshortplanks.com";

is ($it->result, $replaced, "replaced properly");



