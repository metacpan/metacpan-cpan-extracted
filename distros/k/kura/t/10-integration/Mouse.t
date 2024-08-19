use Test2::V0;
use Test2::Require::Module 'Mouse', 'v2.5.11';

use Mouse::Util::TypeConstraints;

subtest 'Test `kura` with Mouse' => sub {
    use kura Foo => subtype 'Name', as 'Str', where { length $_ > 0 };

    isa_ok Foo, 'Mouse::Meta::TypeConstraint';

    ok !Foo->check('');
    ok Foo->check('foo');
};

done_testing;
