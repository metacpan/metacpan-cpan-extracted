use Test2::V0;
use Test2::Require::Module 'MooseX::Types', '0.50';

use FindBin qw($Bin);
use lib "$Bin";

use TestMooseXTypes qw(Foo);

subtest 'Test `kura` with MooseX::Types' => sub {
    isa_ok Foo, 'Moose::Meta::TypeConstraint';

    ok !Foo->check('');
    ok Foo->check('foo');
};

done_testing;
