use Test2::V0;
use Test2::Require::Module 'Specio', '0.48';

use Specio::Declare;

subtest 'Test `kura` with Specio' => sub {
    use kura Foo => declare 'Name', where  => sub { length $_[0] > 0 };

    isa_ok Foo, 'Specio::Constraint::Simple';

    ok !Foo->check('');
    ok Foo->check('hoge');
};

done_testing;
