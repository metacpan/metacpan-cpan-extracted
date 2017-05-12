#!perl -w

use strict;
use Test::More tests => 4;


my $string = "foo http://thegestalt.org/simon/ fooo";

use_ok('URI::Find::Iterator');

my $it;
ok($it = URI::Find::Iterator->new($string), "create new");

my @uris = qw(http://thegestalt.org/simon/); 
while (my $match = $it->match()) {
	my $target = shift @uris;
	is($match, $target, "matched $target");
}


is ($it->result, $string, "replaced properly");



