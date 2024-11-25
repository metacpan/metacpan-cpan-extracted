use Test2::V0;
use Test2::Require::Module 'Mouse', 'v2.5.11';

use FindBin qw($Bin);
use lib "$Bin";

use TestMouse qw(Foo);

subtest 'Test `kura` with Mouse' => sub {
    isa_ok Foo, 'Mouse::Meta::TypeConstraint';

    ok !Foo->check('');
    ok Foo->check('foo');
};

done_testing;
