use strict;
use warnings;
use Test::More;

use Type::Nano qw( Int );

my $twos = Type::Nano->new(
	name       => 'Twos',
	parent     => Int,
	constraint => sub { /2/ },
);

ok $twos->check( '2' );
ok $twos->check( '123' );
ok !$twos->check( '456' );
ok !$twos->check( 'Pina2bo' );

done_testing;
