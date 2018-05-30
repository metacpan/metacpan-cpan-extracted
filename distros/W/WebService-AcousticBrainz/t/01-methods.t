#!perl
use Test::More;

use_ok 'WebService::AcousticBrainz';

my $obj = eval { WebService::AcousticBrainz->new };
isa_ok $obj, 'WebService::AcousticBrainz';

done_testing();
