use Test::More qw{ no_plan };

use_ok( 'Time::Checkpoint' );

our $first = 1;

my $t = Time::Checkpoint->new( );

ok( $t, "object created" );
ok( ref $t eq 'Time::Checkpoint', "object is what we expected" );

my @friends = qw{ burrito pie sauce and anchovies };

$t->checkpoint( $_ ) for @friends;

ok( $t->checkpoint( $_ ), "friend $_ had positive delta" )
	for @friends;

# jaa // vim:tw=80:ts=2:noet:syntax=perl
