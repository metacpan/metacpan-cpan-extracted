use strict;
use warnings;
use Test::More;

use Type::Nano qw( Bool Int intersection );

my $i1 = intersection 'BoolAndInt' => [ Bool, Int ];
ok $i1->check( 0 );
ok $i1->check( 1 );
ok !$i1->check( 2 );
ok !$i1->check( '' );

my $i2 = intersection [ Bool, Int ];
ok $i2->check( 0 );
ok $i2->check( 1 );
ok !$i2->check( 2 );
ok !$i2->check( '' );

done_testing;
