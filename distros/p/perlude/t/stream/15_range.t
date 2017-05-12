use strict;
use warnings;
use Test::More tests => 12;
use Perlude;

is_deeply [ fold range(1, 1, 1)  ], [ 1 ];
is_deeply [ fold range(1, 2, 1)  ], [ 1, 2 ];
is_deeply [ fold range(1, 1)     ], [ 1 ];
is_deeply [ fold range(1, 2)     ], [ 1, 2 ];
is_deeply [ fold range(2, 1, -1) ], [ 2, 1 ];
is_deeply [ fold range(1, 1, -1) ], [ 1 ];
is_deeply [ fold range(1, 0, -1) ], [ 1, 0 ];

diag "infinite ranges";
is_deeply [ fold take 3, range(1, undef)     ], [ 1, 2, 3 ];
is_deeply [ fold take 3, range(1, undef,  1) ], [ 1, 2, 3 ];
is_deeply [ fold take 3, range(1, undef,  2) ], [ 1, 3, 5 ];
is_deeply [ fold take 3, range(5, undef, -1) ], [ 5, 4, 3 ];
is_deeply [ fold take 3, range(5, undef, -2) ], [ 5, 3, 1 ];
