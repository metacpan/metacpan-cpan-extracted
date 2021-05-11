#! perl -I. -w
use t::Test::abeltje;

require_ok( 'V' );

my $version = V::get_version('V_Version');

is($version, "v1.2.3", "Got version: $version");

abeltje_done_testing();
