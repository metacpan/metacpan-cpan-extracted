use Test2::V0;
use Test2::Require::Module 'Data::Checks', '0.09';

use Data::Checks qw(StrEq);

subtest 'Test `kura` with Data::Checks' => sub {
    use kura Foo => StrEq('foo');

    isa_ok Foo, 'Data::Checks::Constraint';

    ok Foo->check('foo');
    ok !Foo->check('bar');
};

done_testing;
