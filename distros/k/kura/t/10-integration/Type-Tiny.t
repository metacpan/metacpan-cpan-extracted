use Test2::V0;
use Test2::Require::Module 'Type::Tiny', '2.000000';

use Types::Standard -types;

subtest 'Test `kura` with Type::Tiny' => sub {
    use kura Foo => Str & sub { length $_ > 0 };

    isa_ok Foo, 'Type::Tiny';

    ok !Foo->check('');
    ok Foo->check('hoge');
};

done_testing;
