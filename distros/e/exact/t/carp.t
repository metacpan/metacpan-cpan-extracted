use Test2::V0;
use exact;

like( dies { croak('test failure success') }, qr/^test failure success/, 'croak' );

done_testing;
