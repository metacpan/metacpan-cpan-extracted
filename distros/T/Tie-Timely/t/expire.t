use Test::More 1;

my $class = 'Tie::Timely';

BAILOUT() unless use_ok( $class );

my $expiry =  3;
my $value  = 37;

tie my $scalar, $class, $value, $expiry;

is $scalar, $value, 'Has set value right after setup';

sleep( $expiry + 1 );

is $scalar, undef, 'Scalar loses value after expiry time';

done_testing();
