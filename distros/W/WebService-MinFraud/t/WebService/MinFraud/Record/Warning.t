use strict;
use warnings;

use Test::More 0.88;

use WebService::MinFraud::Record::Warning;

my $warning = WebService::MinFraud::Record::Warning->new(
    code    => 'INPUT_INVALID',
    warning =>,
    'Encountered value at /shipping/city that does not meet the required constraints',
    input_pointer => '/shipping/city',
);

is( $warning->code, 'INPUT_INVALID', 'code' );
like( $warning->warning, qr/city that does not meet/, 'city' );
is_deeply( $warning->input_pointer, '/shipping/city', 'input' );

done_testing;
