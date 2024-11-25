use Test2::V0;
use Test2::Require::Module 'Moo', '2.005005';
use Test2::Require::Module 'Type::Tiny', '2.000000';

use FindBin qw($Bin);
use lib "$Bin";

use TestMoo qw(Foo);

subtest 'Test `kura` with Moo' => sub {
    # Moo accepts Type::Tiny
    isa_ok Foo, 'Type::Tiny';

    ok !Foo->check('');
    ok Foo->check('foo');
};

done_testing;
