#!perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;

=pod

This is a simple test using multiple providers
and done as two different `use` calls to make
sure the mechanism can do that.

=cut

{
    package Bar::Decorator::Provider;
    use strict;
    use warnings;

    use decorators ':for_providers';

    our $DECORATOR_USED = 0;

    sub Bar : Decorator { $DECORATOR_USED++; return }

    package Baz::Decorator::Provider;
    use strict;
    use warnings;

    use decorators ':for_providers';

    our $DECORATOR_USED = 0;

    sub Baz : Decorator { $DECORATOR_USED++; return }

    package Foo;
    use strict;
    use warnings;

    use decorators qw[
        Bar::Decorator::Provider
        Baz::Decorator::Provider
    ];

    sub new { bless +{} => $_[0] }

    sub foo : Bar { 'FOO' }
    sub bar : Baz { 'BAR' }

    sub gorch : Bar Baz { 'GORCH' }
}

BEGIN {
    is($Bar::Decorator::Provider::DECORATOR_USED, 2, '...the decorator was used in BEGIN');
    is($Baz::Decorator::Provider::DECORATOR_USED, 2, '...the decorator was used in BEGIN');
    can_ok('Foo', 'MODIFY_CODE_ATTRIBUTES');
    can_ok('Foo', 'FETCH_CODE_ATTRIBUTES');
}

# and in runtime ...
#ok(!Foo->can('MODIFY_CODE_ATTRIBUTES'), '... the MODIFY_CODE_ATTRIBUTES has been removed');
can_ok('Foo', 'FETCH_CODE_ATTRIBUTES');

{
    my $foo = Foo->new;
    isa_ok($foo, 'Foo');

    can_ok($foo, 'foo');
    can_ok($foo, 'bar');
    can_ok($foo, 'gorch');

    is($foo->foo, 'FOO', '... the method worked as expected');
    is($foo->bar, 'BAR', '... the method worked as expected');
    is($foo->gorch, 'GORCH', '... the method worked as expected');
}

{
    my $method = MOP::Class->new( 'Foo' )->get_method('foo');
    isa_ok($method, 'MOP::Method');
    is_deeply(
        [ map $_->original, $method->get_code_attributes ],
        [qw[ Bar ]],
        '... got the expected attributes'
    );
}

{
    my $method = MOP::Class->new( 'Foo' )->get_method('bar');
    isa_ok($method, 'MOP::Method');
    is_deeply(
        [ map $_->original, $method->get_code_attributes ],
        [qw[ Baz ]],
        '... got the expected attributes'
    );
}

{
    my $method = MOP::Class->new( 'Foo' )->get_method('gorch');
    isa_ok($method, 'MOP::Method');
    is_deeply(
        [ map $_->original, $method->get_code_attributes ],
        [qw[ Bar Baz ]],
        '... got the expected attributes'
    );
}

done_testing;

