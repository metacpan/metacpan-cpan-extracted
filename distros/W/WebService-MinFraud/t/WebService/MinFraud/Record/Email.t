use strict;
use warnings;

use Test::More 0.88;

use WebService::MinFraud::Record::Email;

my $email = WebService::MinFraud::Record::Email->new(
    is_free      => 1,
    is_high_risk => 0,
);

is( $email->is_free,      1, 'email is free' );
is( $email->is_high_risk, 0, 'email is not high risk' );

done_testing;
