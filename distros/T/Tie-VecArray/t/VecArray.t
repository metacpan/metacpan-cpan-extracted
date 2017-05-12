#!/usr/bin/perl -w

use strict;
use Test::More tests => 17;

use_ok 'Tie::VecArray';

my @array;
my $obj = tie @array, 'Tie::VecArray', 16;

isa_ok( $obj, 'Tie::VecArray',                        'basic tie()'   );
is( $obj->bits, 16,                                    'get bits()'   );
is( $#array, -1,                              'null FETCHSIZE()'      );
is( @array, 0,                                'null FETCHSIZE() again');

$#array = 5;
is( @array, 6,                                        'STORESIZE()'   );

$array[5] = 42;
is( $array[5], 42,                         'simple STORE & FETCH'       );
is( pop(@array), 42 );
is( @array, 5,                                          'simple POP'    );
ok( push(@array, 100) );
is( $array[5], 100 );
is( @array, 6,                                         'simple PUSH'    );
ok( $obj->bits(8) );
is( @array, 12,                                 'simple bits() change'  );


my @vec;
my $vec_obj = tie @vec, 'Tie::VecArray', 1;

@vec[0..4] = (1) x 5;

is( @vec, 5,                           'one bit FETCHSIZE'     );

$vec_obj->bits(2);
is( @vec, 3,                           'two bit FETCHSIZE'     );

$vec_obj->bits(1);
is( @vec, 6,                   'back to one bit FETCHSIZE'     );
