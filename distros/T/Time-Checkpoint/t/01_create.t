use Test::More tests => 3;

use_ok( 'Time::Checkpoint' );

my $t = Time::Checkpoint->new();

ok( $t, "object created" );
ok( ref $t eq 'Time::Checkpoint', "object is what we expected" );

# jaa // vim:tw=80:ts=2:noet:syntax=perl
