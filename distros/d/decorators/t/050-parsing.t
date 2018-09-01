#!perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;

=pod

This is a simple test using a single provider ...

=cut

{
    package Bar::Decorator::Provider;
    use strict;
    use warnings;

    use decorators ':for_providers';

    our $DECORATOR_USED = 0;

    sub Bar : Decorator { $DECORATOR_USED++; return }

    package Foo;
    use strict;
    use warnings;

    use decorators 'Bar::Decorator::Provider';

    sub new { bless +{} => $_[0] }

    sub foo : Bar(
        'Baz',
        10 => 20,
        undef
    ) { 'FOO' }
}

BEGIN {
    is($Bar::Decorator::Provider::DECORATOR_USED, 1, '...the trait was used in BEGIN');
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

    is($foo->foo, 'FOO', '... the method worked as expected');
}

{

    my $method = MOP::Class->new( 'Foo' )->get_method('foo');
    isa_ok($method, 'MOP::Method');
    is_deeply(
        [ map $_->original, $method->get_code_attributes ],
        [
    q[Bar(
        'Baz',
        10 => 20,
        undef
    )]
        ],
        '... got the expected attributes'
    );

    my ($trait) = $method->get_code_attributes;
    isa_ok($trait, 'MOP::Method::Attribute');

    is($trait->name, 'Bar', '... got the expected trait name');
    is_deeply(
        $trait->args,
        [ 'Baz', 10, 20, undef ],
        '... got the values we expected'
    );
}

done_testing;

