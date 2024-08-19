use Test2::V0;
use Test2::Require::Module 'Moo', '2.005005';
use Test2::Require::Module 'Type::Tiny', '2.000000';

use Moose::Util::TypeConstraints;

subtest 'Test `kura` with Moo' => sub {
    use kura Foo => sub { $_[0] eq 'foo' };

    # Moo accepts Type::Tiny
    isa_ok Foo, 'Type::Tiny';

    ok !Foo->check('');
    ok Foo->check('foo');
};

done_testing;
