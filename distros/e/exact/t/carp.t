use Test2::V0;
use exact -noautoclean;

like( dies { croak('test failure success') }, qr/^test failure success/, 'croak' );

done_testing;
