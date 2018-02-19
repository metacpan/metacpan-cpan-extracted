#!perl
use Test::More;

use_ok 'WebService::Hooktheory';

my $obj = eval { WebService::Hooktheory->new };
isa_ok $obj, 'WebService::Hooktheory';

# XXX Not sure how to test this. :\

done_testing();
