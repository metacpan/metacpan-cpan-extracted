use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Deep;

use Test::Mock::One;
use Data::Dumper;

{
    eval "use List::Util 1.33";
    if ($@) {
        BAIL_OUT("List::Util 1.33 not installed");
    }
}

{
    note "Basics";

    my $mock = Test::Mock::One->new(
        foo  => 'bar',
        bar  => 1,
        time => Data::Dumper->new([]),
        deep => { foo => 'inside' },
        code => sub {
            return "this is code: " . shift;
        },
        array    => [qw(foo bar baz)],
        nested   => { nest => { nested_array => [qw(foo bar baz)] } },
        ArrayRef => \[qw(foo bar baz)],
        HashRef     => \{ foo => 'bar' },
        underground => "jamiroquai"
    );

    ok(UNIVERSAL::isa($mock, 'Test::Mock::One'), "We are Test::Mock::One");
    isa_ok($mock, 'Foo', "Mocked our ISA");

    is($mock->foo, 'bar', 'returns string');
    is($mock->bar, 1,     'returns int');
    is($mock->code("'foo'"), "this is code: 'foo'", "Executed code");

    my $rv = $mock->array->foo;
    isa_ok($rv, "Foo", "Array mocks ISA");
    ok(UNIVERSAL::isa($rv, 'Test::Mock::One'), "Array is Test::Mock::One");
    $rv = $mock->nested->nest->nested_array;

    cmp_deeply($mock->ArrayRef, [qw(foo bar baz)], "Array ref dealing");
    cmp_deeply($mock->HashRef, { foo => 'bar' }, "Hash ref dealing");
    isa_ok($mock->time, 'Data::Dumper', "is a Data::Dumper object");

    $rv = $mock->yep->baz->diaz;
    ok(UNIVERSAL::isa($rv, 'Test::Mock::One'), "Just keep calling");

    is($mock->deep->foo, 'inside', "deep inside");

    is($mock->deeper->underground, "jamiroquai", "We keep return \$self");
}

{
    note "Mocking ISA";

    my $mock = Test::Mock::One->new("X-Mock-ISA" => "Foo",);

    isa_ok($mock, "Foo", "We are Foo");
    ok(!$mock->isa("Bar"), "We aren't Bar");

    $mock = Test::Mock::One->new("X-Mock-ISA" => [qw(Foo Bar)],);

    isa_ok($mock, "Foo", "We are Foo");
    isa_ok($mock, "Bar", "We are Bar");
    ok(!$mock->isa("Baz"), "We aren't Baz");

    $mock = Test::Mock::One->new("X-Mock-ISA" =>
            sub { my $type = shift; return 1 if $type eq 'Foo'; return 0 },);

    isa_ok($mock, "Foo", "We are Foo");
    ok(!$mock->isa("Bar"), "We aren't Bar");

    $mock = Test::Mock::One->new("X-Mock-ISA" => qr/Foo$/);
    isa_ok($mock, "Foo", "We are Foo");
    ok(!$mock->isa("Fo"), "We aren't Fo");

    $mock = Test::Mock::One->new("X-Mock-ISA" => undef);
    ok(!$mock->isa("Foo"), "We aren't Foo");
}

{
    note "Strict mode";
    my $mock = Test::Mock::One->new(
        "X-Mock-Strict" => 1,
        foo             => 1,
    );
    lives_ok(sub { $mock->foo }, "foo is allowed");

    throws_ok(
        sub {
            $mock->bar;
        },
        qr/Using Test::Mock::One in strict mode, called undefined function 'bar'/,
        "Strict mode does not allow undefined methods"
    );

    can_ok($mock, 'foo');
    ok(!$mock->can('bar'), "can't do bar");

    $mock = Test::Mock::One->new(
        "X-Mock-Strict" => 0,
        foo             => 1,
    );
    lives_ok(sub { $mock->foo }, "foo is allowed");
    lives_ok(sub { $mock->bar }, "bar is allowed");

    can_ok($mock, 'foo', \"mock can foo");

}

{
    note "Stringification";
    my $mock = Test::Mock::One->new();
    is("$mock", 'Test::Mock::One stringified', "The default");

    $mock = Test::Mock::One->new("X-Mock-Stringify" => undef,);
    is("$mock", 'Test::Mock::One stringified', "The default");
    $mock = Test::Mock::One->new("X-Mock-Stringify" => 1,);
    is("$mock", 1, "Stringify to 1");


    $mock = Test::Mock::One->new("X-Mock-Stringify" => sub { return "foo" } );
    is("$mock", 'foo', "Code works too");
}

{
    note "SelfArg";

    my $mock = Test::Mock::One->new(
        'X-Mock-SelfArg'   => 1,
        'X-Mock-Stringify' => sub {
            my $self = shift;
            if ($self->foo eq 'bar') {
                return $self->foo;
            }
            return "not bar";
        },
        'X-Mock-ISA' => sub {
            my $self = shift;
            if ($self->foo eq 'bar') {
                return 0;
            }
            return 1;
        },
        code => sub {
            my $self  = shift;
            my $key   = shift;
            my $value = shift;
            $self->{$key} = $value;
        },
    );

    $mock->code('foo', "bar");
    is($mock->foo . "", 'bar', "self->{foo} has been set to bar");
    ok(!$mock->isa("Foo"), "We aren't Foo because self->foo eq 'bar'");
    is($mock . "", "bar", "We stringify to 'bar'");

    $mock->code('foo', "baz");
    is($mock->foo, 'baz', "self->{foo} has been set to bar");
    isa_ok($mock, "Foo", "We are Foo because self->foo eq 'baz'");
    is($mock . "", "not bar", "We stringify to 'not bar'");

}

{
    note "Copy X-Mock-XXX attributes";

    my $mock = Test::Mock::One->new(
        strict             => { foo => { bar => 'baz' }, bar => [qw(sup lo)], },

        'X-Mock-Strict'    => 1,
        'X-Mock-Stringify' => 'Foo',
        'X-Mock-ISA'       => 'X-Copy',
        'X-Mock-SelfArg'   => 1,
    );

    throws_ok(
        sub {
            $mock->strict->foo->baz;
        },
        qr/Using Test::Mock::One in strict mode, called undefined function 'baz'/,
        "Strict mode copy works"
    );

    is("". $mock->strict->foo, "Foo", "X-Mock-Stringify copy works");

    isa_ok($mock->strict->foo, "X-Copy", "X-Mock-ISA copy works");
    ok(!$mock->strict->foo->isa("Foo"), "X-Mock-ISA copy works isa()");

    isa_ok($mock->strict->bar->sup, "X-Copy", "X-Mock-ISA copy works on arrayrefs");
    ok(!$mock->strict->bar->sup->isa("Foo"), "X-Mock-ISA copy works on arrayrefs isa()");

    is($mock->strict->foo->{'X-Mock-SelfArg'}, 1, "X-Mock-SelfArg is present");

}

done_testing();
