use Test2::V0;

use Types::Common -all;
use Types::Capabilities -types;

signature_for blah => ( pos => [ Greppable & Eachable ] );

sub blah {
	my $list = shift;
	my @r;
	$list
		->grep( sub { /foo/ } )
		->grep( sub { /lish/ } )
		->each( sub { push @r, $_ } );
	return \@r;
}

is( blah( [qw/ foo foolish delish bar /] ), [ 'foolish' ] );

is( ( Greppable & Mappable )->display_name, 'Greppable&Mappable' );

is( ( Greppable & Mappable )->{autobox}, Greppable->{autobox} );

done_testing;
