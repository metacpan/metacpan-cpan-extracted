# NAME

Test::Mock::Guard - Simple mock test library using RAII.

# SYNOPSIS

    use Test::More;
    use Test::Mock::Guard qw(mock_guard);

    package Some::Class;

    sub new { bless {} => shift }
    sub foo { "foo" }
    sub bar { 1; }

    package main;

    {
        my $guard = mock_guard( 'Some::Class', { foo => sub { "bar" }, bar => 10 } );
        my $obj = Some::Class->new;
        is( $obj->foo, "bar" );
        is( $obj->bar, 10 );
    }

    my $obj = Some::Class->new;
    is( $obj->foo, "foo" );
    is( $obj->bar, 1 );

    done_testing;

# DESCRIPTION

Test::Mock::Guard is mock test library using RAII.
This module is able to change method behavior by each scope. See SYNOPSIS's sample code.

# EXPORT FUNCTION

## mock\_guard( @class\_defs )

@class\_defs have the following format.

- key

    Class name or object to mock.

- value

    Hash reference. Keys are method names; values are code references or scalars.
    If the value is code reference, it is used as a method.
    If the value is a scalar, the method will return the specified value.

You can mock instance methods as well as class methods (this feature was provided by cho45):

    use Test::More;
    use Test::Mock::Guard qw(mock_guard);

    package Some::Class;

    sub new { bless {} => shift }
    sub foo { "foo" }

    package main;

    my $obj1 = Some::Class->new;
    my $obj2 = Some::Class->new;

    {
        my $obj2 = Some::Class->new;
        my $guard = mock_guard( $obj2, { foo => sub { "bar" } } );
        is ($obj1->foo, "foo", "obj1 has not changed" );
        is( $obj2->foo, "bar", "obj2 is mocked" );
    }

    is( $obj1->foo, "foo", "obj1" );
    is( $obj2->foo, "foo", "obj2" );

    done_testing;

# METHODS

## new( @class\_defs )

See ["mock_guard"](#mock_guard) definition.

## call\_count( $class\_name\_or\_object, $method\_name )

Returns a number of calling of $method\_name in $class\_name\_or\_object.

# AUTHOR

Toru Yamaguchi <zigorou@cpan.org>

Yuji Shimada <xaicron at cpan.org>

Masaki Nakagawa <masaki@cpan.org>

# THANKS TO

cho45 <cho45@lowreal.net>

# SEE ALSO

[Test::MockObject](https://metacpan.org/pod/Test::MockObject)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
