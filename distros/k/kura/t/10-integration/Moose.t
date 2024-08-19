use Test2::V0;
use Test2::Require::Module 'Moose', '2.2207';

use Moose::Util::TypeConstraints;

subtest 'Test `kura` with Moose' => sub {
    use kura Foo => subtype 'Name', as 'Str', where { length $_ > 0 };

    isa_ok Foo, 'Moose::Meta::TypeConstraint';

    ok !Foo->check('');
    ok Foo->check('foo');
};

done_testing;
