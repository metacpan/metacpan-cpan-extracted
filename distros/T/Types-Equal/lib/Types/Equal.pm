package Types::Equal;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.02";

use Type::Library -base, -declare => qw( Eq Equ NumEq NumEqu );
use Type::Tiny::Eq;
use Type::Tiny::Equ;
use Type::Tiny::NumEq;
use Type::Tiny::NumEqu;

my $meta = __PACKAGE__->meta;

$meta->add_type(
    {
        name => 'Eq',
        constraint_generator => sub {
            Type::Tiny::Eq->new(
                value => $_[0],
            )
        }
    }
);

$meta->add_type(
    {
        name => 'Equ',
        constraint_generator => sub {
            Type::Tiny::Equ->new(
                value => $_[0],
            )
        }
    }
);

$meta->add_type(
    {
        name => 'NumEq',
        constraint_generator => sub {
            Type::Tiny::NumEq->new(
                value => $_[0],
            )
        }
    }
);

$meta->add_type(
    {
        name => 'NumEqu',
        constraint_generator => sub {
            Type::Tiny::NumEqu->new(
                value => $_[0],
            )
        }
    }
);

1;
__END__

=encoding utf-8

=head1 NAME

Types::Equal - type constraints for single value equality

=head1 SYNOPSIS

    use Types::Equal qw( Eq Equ );
    use Types::Standard -types;
    use Type::Utils qw( match_on_type );

    # Check single string equality
    my $Foo = Eq['foo'];
    $Foo->check('foo'); # true
    $Foo->check('bar'); # false

    eval { Eq[undef]; };
    ok $@; # dies


    # Check single string equality with undefined
    my $Bar = Equ['bar'];
    $Bar->check('bar'); # true

    my $Undef = Equ[undef];
    $Undef->check(undef);


    # Can combine with other types
    my $Baz = Eq['baz'];
    my $ListBaz = ArrayRef[$Baz];
    my $Type = $ListBaz | $Baz;

    $Type->check(['baz']); # true
    $Type->check('baz'); # true

    # Easily use pattern matching
    my $Publish = Eq['publish'];
    my $Draft = Eq['draft'];

    my $post = {
        status => 'publish',
        title => 'Hello World',
    };

    match_on_type($post->{status},
        $Publish => sub { "Publish!" },
        $Draft => sub { "Draft..." },
    ) # => Publish!;


    # Create simple Algebraic Data Types(ADT)
    my $LoginUser = Dict[
        _type => Eq['LoginUser'],
        id => Int,
        name => Str,
    ];

    my $Guest = Dict[
        _type => Eq['Guest'],
        name => Str,
    ];

    my $User = $LoginUser | $Guest;

    my $user = { _type => 'Guest', name => 'ken' };
    $User->assert_valid($user);

    match_on_type($user,
        $LoginUser => sub { "You are LoginUser!" },
        $Guest => sub { "You are Guest!" },
    ) # => 'You are Guest!';

=head1 DESCRIPTION

Types::Equal provides type constraints for single string equality like TypeScript's string literal types.

=head2 Eq

C<Eq> is function of a type constraint L<Type::Tiny::Eq> which is for single string equality.

=head2 Equ

C<Equ> is function of a type constraint L<Type::Tiny::Equ> which is for single string equality with undefined.

=head2 NumEq

C<NumEq> is function of a type constraint L<Type::Tiny::NumEq> which is for single number equality.

=head2 NumEqu

C<NumEqu> is function of a type constraint L<Type::Tiny::NumEqu> which is for single number equality with undefined.

=head1 LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kobaken E<lt>kfly@cpan.orgE<gt>

=cut

