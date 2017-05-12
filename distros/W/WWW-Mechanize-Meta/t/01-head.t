#!perl

use Test::More tests => 3;

BEGIN {
	use_ok( 'WWW::Mechanize::Meta' );
	use_ok( 'Data::Dumper' );
}
my $mech=WWW::Mechanize::Meta->new();
$mech->get('http://search.cpan.org');
ok($mech->headtag);
