use Test2::V0;
use Test2::Require::Module 'Data::Checks', '0.09';

use FindBin qw($Bin);
use lib "$Bin";

use TestDataChecks qw(Foo);

subtest 'Test `kura` with Data::Checks' => sub {
    isa_ok Foo, 'Data::Checks::Constraint';

    ok Foo->check('foo');
    ok !Foo->check('bar');
};

done_testing;
