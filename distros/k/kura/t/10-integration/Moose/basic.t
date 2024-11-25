use Test2::V0;
use Test2::Require::Module 'Moose', '2.2207';

use FindBin qw($Bin);
use lib "$Bin";

use TestMoose qw(Foo);

subtest 'Test `kura` with Moose' => sub {
    isa_ok Foo, 'Moose::Meta::TypeConstraint';

    ok !Foo->check('');
    ok Foo->check('foo');
};

done_testing;
