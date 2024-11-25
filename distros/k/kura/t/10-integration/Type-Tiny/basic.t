use Test2::V0;
use Test2::Require::Module 'Type::Tiny', '2.000000';

use FindBin qw($Bin);
use lib "$Bin";

use TestTypeTiny qw(Foo);

subtest 'Test `kura` with Type::Tiny' => sub {
    isa_ok Foo, 'Type::Tiny';

    ok !Foo->check('');
    ok Foo->check('hoge');
};

done_testing;
