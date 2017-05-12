
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok('WebService::SendGrid3');

my $SendGrid = WebService::SendGrid3->new(
    username => 'a',
    password => 'b',
);

isa_ok($SendGrid, 'WebService::SendGrid3');

my $rh = {
    a => [ 'x', 'y', 'z' ],
};

is($SendGrid->_serialise_for_get(
    'a',
    $rh->{a},
),
   "x&a=y&a=z", 'Check _serialise_for_get()');

done_testing();
