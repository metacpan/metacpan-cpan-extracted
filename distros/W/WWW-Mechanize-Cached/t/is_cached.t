use strict;
use warnings;

use Test::More;
use WWW::Mechanize::Cached ();

my $mech = WWW::Mechanize::Cached->new;

ok( !defined( $mech->is_cached ), 'is_cached should default to undef' );

done_testing();
