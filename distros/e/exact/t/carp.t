use Test2::V0;
use exact;

like( dies { croak('test failure success') }, qr/^test failure success/, 'croak' );
is( dies { die deat "Error at program.pl line 42.\n" }, "Error\n", 'deat' );
is( deattry { return 42 }, 42, 'deattry success' );
is( dies { deattry { die "Exception" } }, "Exception\n", 'deattry failure' );

done_testing;
