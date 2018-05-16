use strict;
use warnings;

use Test::More 0.88;
use WebService::MinFraud::Model::Chargeback;

subtest 'Can create a chargeback object' => sub {
    my $class = 'WebService::MinFraud::Model::Chargeback';
    my $model = $class->new;

    isa_ok( $model, $class );
};

done_testing;
