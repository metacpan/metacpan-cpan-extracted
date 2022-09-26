use strict;
use warnings;
use Test::More;

use Type::Nano qw( class_type );

{
	package Local::Parent;
	sub xyz { 1 }
}

{
	package Local::Child;
	use vars '@ISA';
	@ISA = 'Local::Parent';
}

my $c1 = class_type 'Local::Parent';
ok $c1->check( bless {}, 'Local::Parent' );
ok $c1->check( bless [], 'Local::Parent' );
ok $c1->check( bless {}, 'Local::Child' );
ok !$c1->check( bless {}, 'Local::Child2' );
ok !$c1->check( 'Local::Parent' );

done_testing;
