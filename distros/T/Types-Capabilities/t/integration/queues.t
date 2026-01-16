use Test2::V0;

use Data::Dumper;
use Types::Common -all;
use Types::Capabilities -types;

signature_for take_one => ( pos => [ Dequeueable ] );

sub take_one {
	my $queue = shift;
	return $queue->dequeue;
}

my $array = [ qw/ foo bar baz / ];

is( take_one($array), 'foo' );
is( take_one($array), 'bar' );
is( take_one($array), 'baz' );
is( $array, [] );

my $array2 = [ qw/ foo bar baz / ];
my $cb = sub {
	return if !@$array2;
	shift @$array2;
};

is( take_one($cb), 'foo' );
is( take_one($cb), 'bar' );
is( take_one($cb), 'baz' );
is( $array2, [] );

my $q = ( Enqueueable & Dequeueable )->coerce( sub {
	use feature 'state';
	state $list = [];
	return push @$list, $_[0] if @_;
	return if !@$list;
	shift @$list;
} );

$q->enqueue( 1 );
$q->enqueue( 2 );
is( $q->dequeue, 1 );
$q->enqueue( 3 );
is( $q->dequeue, 2 );
is( $q->dequeue, 3 );
is( $q->dequeue, undef );

done_testing;
