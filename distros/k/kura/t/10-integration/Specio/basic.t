use Test2::V0;
use Test2::Require::Module 'Specio', '0.48';

use FindBin qw($Bin);
use lib "$Bin";

use TestSpecio qw(Foo);

subtest 'Test `kura` with Specio' => sub {
    isa_ok Foo, 'Specio::Constraint::Simple';

    ok !Foo->check('');
    ok Foo->check('hoge');
};

done_testing;
