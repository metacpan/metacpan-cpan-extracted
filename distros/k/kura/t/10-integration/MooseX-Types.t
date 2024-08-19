use Test2::V0;
use Test2::Require::Module 'MooseX::Types', '0.50';

use MooseX::Types::Moose qw( Str );

subtest 'Test `kura` with MooseX::Types' => sub {
    use kura Foo => Str->create_child_type(constraint => sub { length $_ > 0 });

    isa_ok Foo, 'Moose::Meta::TypeConstraint';

    ok !Foo->check('');
    ok Foo->check('foo');
};

done_testing;
