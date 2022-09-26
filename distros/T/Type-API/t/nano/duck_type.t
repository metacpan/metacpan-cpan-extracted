use strict;
use warnings;
use Test::More;

use Type::Nano qw( duck_type );

{
	package Local::Parent;
	sub xyz { 1 }
}

{
	package Local::Child;
	use vars '@ISA';
	@ISA = 'Local::Parent';
}

my $c1 = duck_type 'CanXyz', [ 'xyz' ];
ok $c1->check( bless {}, 'Local::Parent' );
ok $c1->check( bless [], 'Local::Parent' );
ok $c1->check( bless {}, 'Local::Child' );
ok !$c1->check( bless {}, 'Local::Child2' );
ok !$c1->check( 'Local::Parent' );

my $c2 = duck_type [ 'xyz' ];
ok $c2->check( bless {}, 'Local::Parent' );
ok $c2->check( bless [], 'Local::Parent' );
ok $c2->check( bless {}, 'Local::Child' );
ok !$c2->check( bless {}, 'Local::Child2' );
ok !$c2->check( 'Local::Parent' );

my $c3 = duck_type 'CanXyz', 'xyz';
ok $c3->check( bless {}, 'Local::Parent' );
ok $c3->check( bless [], 'Local::Parent' );
ok $c3->check( bless {}, 'Local::Child' );
ok !$c3->check( bless {}, 'Local::Child2' );
ok !$c3->check( 'Local::Parent' );

done_testing;
