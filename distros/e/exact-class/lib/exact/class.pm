package exact::class;
# ABSTRACT: Simple class interface extension for exact

use 5.014;
use exact;
use Role::Tiny ();
use Scalar::Util ();

our $VERSION = '1.08'; # VERSION

my ( $store, $roles );

sub import {
    my ( $self, $caller ) = @_;

    if ($caller) {
        exact->late_parent;
    }
    else {
        $caller //= caller();
        exact->add_isa( $self, $caller ) if ( $self eq 'exact::class');
    }

    $store->{$caller} = {};

    for ( qw( has class_has with ) ) {
        exact->monkey_patch( $caller, $_, \&$_ ) unless ( defined &{ $caller . '::' . $_ } );
    }
}

sub DESTROY {}

sub ____parents {
    my ($namespace) = @_;
    no strict 'refs';
    my @parents = @{ $namespace . '::ISA' };
    return @parents, map { ____parents($_) } @parents;
}

sub ____install {
    my ( $self, $namespace, $input ) = @_;
    if ( ref $store->{$namespace} eq 'HASH' ) {
        for my $name ( keys %{ $store->{$namespace}->{has} } ) {
            if ( exists $input->{$name} ) {
                $self->attr( $name, $input->{$name} );
            }
            elsif ( exists $store->{$namespace}->{value}{$name} ) {
                $self->attr( $name, $store->{$namespace}->{value}{$name} );
            }
            else {
                $self->attr($name);
            }
        }
    }
}

sub new {
    my $class = shift;
    my $input = @_ ? @_ > 1 ? {@_} : { %{ $_[0] } } : {};
    my $self  = bless( { %$input }, ref $class || $class );

    for my $namespace ( reverse ( ref $self, ____parents( ref $self ) ) ) {
        if ( ref $roles->{$namespace} eq 'ARRAY' ) {
            for my $role ( @{ $roles->{$namespace} } ) {
                ____install( $self, $role, $input );
            }
        }

        ____install( $self, $namespace, $input );
    }

    return $self;
}

sub tap {
    my ( $self, $cb ) = ( shift, shift );
    $_->$cb(@_) for $self;
    return $self;
}

sub attr {
    my ( $self, $attrs, $value ) = @_;

    my $set = {
        attrs        => $attrs,
        caller       => ref($self) || $self,
        set_has      => 1,
        self         => $self,
        obj_accessor => 1,
        redefine     => 1,
    };

    $set->{value} = $value if ( @_ > 2 );
    return ____attrs($set);
}

sub class_has {
    my ( $attrs, $value ) = @_;

    my $set = {
        attrs  => $attrs,
        caller => scalar( caller() ),
    };

    $set->{value} = $value if ( @_ > 1 );

    try {
        ____attrs($set);
    }
    catch {
        croak($$_);
    };

    return;
}

sub has {
    my ( $attrs, $value ) = @_;

    my $set = {
        attrs   => $attrs,
        caller  => scalar( caller() ),
        set_has => 1,
    };

    $set->{value} = $value if ( @_ > 1 );

    try {
        ____attrs($set);
    }
    catch {
        croak($$_);
    };

    return;
}

sub ____attrs {
    for my $set (@_) {
        for my $name ( ( ref $set->{attrs} ) ? @{ $set->{attrs} } : $set->{attrs} ) {
            die \"$name already defined"
                if ( not $set->{redefine} and exists $store->{ $set->{caller} }->{name}{$name} );

            my $accessor = ( $set->{obj_accessor} )
                ? sub {
                    my ( $self, $value ) = @_;

                    if ( @_ > 1 ) {
                        $self->{$name} = $value;
                        return $self;
                    }
                    else {
                        return ${ $self->{$name} } if (
                            ref $self->{$name} eq 'REF' and
                            ref ${ $self->{$name} } eq 'CODE'
                        );

                        $self->{$name} = $self->{$name}->($self) if ( ref $self->{$name} eq 'CODE' );
                        return $self->{$name};
                    }
                }
                : sub {
                    my ( $self, $value ) = @_;

                    if ( @_ > 1 ) {
                        $store->{ $set->{caller} }->{value}{$name} = $value;
                        return $self;
                    }
                    else {
                        return ${ $store->{ $set->{caller} }->{value}{$name} } if (
                            ref $store->{ $set->{caller} }->{value}{$name} eq 'REF' and
                            ref ${ $store->{ $set->{caller} }->{value}{$name} } eq 'CODE'
                        );

                        $store->{ $set->{caller} }->{value}{$name} =
                            $store->{ $set->{caller} }->{value}{$name}->($self)
                            if ( ref $store->{ $set->{caller} }->{value}{$name} eq 'CODE' );
                        return $store->{ $set->{caller} }->{value}{$name};
                    }
                };

            {
                no strict 'refs';
                no warnings 'redefine';
                *{ $set->{caller} . '::' . $name } = $accessor;
            }

            if ( ref $set->{self} ) {
                $set->{self}->$name( $set->{value} ) if ( exists $set->{value} );
            }
            else {
                $store->{ $set->{caller} }->{has}{$name}   = 1 if ( $set->{set_has} );
                $store->{ $set->{caller} }->{name}{$name}  = 1;
                $store->{ $set->{caller} }->{value}{$name} = $set->{value} if ( exists $set->{value} );
            }
        }
    }

    return;
}

sub with {
    my $caller = scalar(caller);
    push( @{ $roles->{$caller} }, @_ );
    return Role::Tiny->apply_roles_to_package( $caller, @_ );
}

sub with_roles {
    my ( $self, @roles ) = @_;

    return Role::Tiny->create_class_with_roles(
        $self,
        map { /^\+(.+)$/ ? "${self}::Role::$1" : $_ } @roles
    ) unless ( my $class = Scalar::Util::blessed $self );

    return Role::Tiny->apply_roles_to_object(
        $self,
        map { /^\+(.+)$/ ? "${class}::Role::$1" : $_ } @roles
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

exact::class - Simple class interface extension for exact

=head1 VERSION

version 1.08

=for markdown [![Build Status](https://travis-ci.org/gryphonshafer/exact-class.svg)](https://travis-ci.org/gryphonshafer/exact-class)
[![Coverage Status](https://coveralls.io/repos/gryphonshafer/exact-class/badge.png)](https://coveralls.io/r/gryphonshafer/exact-class)

=head1 SYNOPSIS

    package Cat;
    use exact -class;

    # ...or if you want to use it directly (which will also use exact):
    # use exact::class;

    has name => 'Unnamed';
    has ['age', 'weight'] => 4;

    # ...and just for this inline example we need:
    BEGIN { $INC{'Cat.pm'} = 1 }

    package AttackCat;
    use exact 'Cat';

    has attack => 4;
    has thac0  => -3;

    class_has hp => 42;

    with 'Attack';

    package main;
    use exact;

    my $cat = Cat->new( name => 'Hamlet' );
    say $cat->age;
    say $cat->age(3)->weight(5)->age;

    my $demon = AttackCat->new( attack => 5, hp => 1138 );
    say $demon->tap( sub { $_->thac0(-4) } )->hp;

    $demon->attr( new_attribute => 1024 );
    say $demon->new_attribute;

    my $devil = AttackCat->with_roles('+Claw')->new;

=head1 DESCRIPTION

L<exact::class> is intended to be a simple class interface extension for
L<exact>. See the L<exact> documentation for additional informatioh about
extensions. The intended use of L<exact::class> is via the extension interface
of L<exact>.

    use exact -class, -conf, -noutf8;

However, you can also use it directly, which will also use L<exact> with
default options:

    use exact::class;

Doing either of these will setup your namespace with some methods to make it
easier to use it as a class with a fluent OO interface. Fluent OO interfaces
are a way to design object-oriented APIs around method chaining to create
domain-specific languages, with the goal of making the readablity of the source
code close to written prose.

=head2 Subclasses

Note that L<exact::class> will place itself as a parent to package in which it's
used. If you setup a subclass to your package, that subclass should not also
use L<exact::class>, or else you'll probably end up with an inheritance error.

=head2 "Highly Influenced" Interface

The interface and much of the code is "highly influenced" (i.e. plagiarized)
from the excellent L<Mojo::Base> and L<Role::Tiny>. So much so that you can
replace:

    use Mojo::Base 'Mojolicious';
    use Role::Tiny::With;

...with:

    use exact -class, 'Mojolicious';

=head1 FUNCTIONS

L<exact::class> implements the following functions:

=head2 has

Create attributes and associated accessors for hash-based objects.

    has 'name';
    has [ 'name1', 'name2', 'name3' ];
    has name4 => undef;
    has name5 => 'foo';
    has name6 => sub {...};
    has [ 'name7', 'name8', 'name9' ]    => 'foo';
    has [ 'name10', 'name11', 'name12' ] => sub {...};
    has name13 => \ sub {...};

Then whenever you have an object:

    $object->name('Set This Name'); # returns $object
    say $object->name               # returns 'Set This Name'

See also the L</"attr"> section below.

=head2 class_has

Exactly the same as C<has> except attributes are assigned to the class, not to
the object. Thus, any time you change a C<class_has> value, it changes across
all objects of that class, both present and future instantiated.

=head2 with

    with 'Some::Role1';
    with qw( Some::Role1 Some::Role2 );

Composes a role into the current space via L<Role::Tiny::With>.

If you have conflicts and want to resolve them in favor of Some::Role1, you can
instead write:

    with 'Some::Role1';
    with 'Some::Role2';

You will almost certainly want to read the documentation for L<exact::role> for
writing roles.

=head1 METHODS

L<exact::class> implements the following methods:

=head2 new

    my $object = SubClass->new;
    my $object = SubClass->new( name => 'value' );
    my $object = SubClass->new( { name => 'value' } );

A basic constructor for hash-based objects. You can pass it either a hash or a
hash reference with attribute values.

=head2 attr

    $object->attr('name');
    SubClass->attr('name');
    SubClass->attr( [ 'name1', 'name2', 'name3' ] );
    SubClass->attr( name => 'foo' );
    SubClass->attr( name => sub {...} );
    SubClass->attr( [ 'name1', 'name2', 'name3' ] => 'foo' );
    SubClass->attr( [ 'name1', 'name2', 'name3' ] => sub {...} );
    SubClass->attr( name => sub {...} );
    SubClass->attr( name => undef );
    SubClass->attr( [ 'name1', 'name2', 'name3' ] => sub {...} );
    SubClass->attr( 'name13' => \ sub {...} );

Create attribute accessors for hash-based objects, an array reference can be
used to create more than one at a time. Pass an optional second argument to set
a default value, it should be a constant, a callback, or a reference to a
callback.

The direct callback will be executed at accessor read time if there's no set
value, and gets passed the current instance of the object as first argument.
Accessors can be chained, that means they return their invocant when they are
called with an argument.

=head3 Code References

Code references will be called on first access and passed a copy of the object.
The return value of the code references will be saved in the attribute,
replacing the reference.

    package Cat;
    use exact -class;
    my $base = 41;
    has name6 => sub { return ++$base };

    package main;
    my $cat = Cat->new;
    say $cat->name6; # 42
    say $cat->name6; # 42

If you instead need a code reference stored permanently in an attribute, then
use a reference to a code reference:

    package Cat;
    use exact -class;
    my $base = 41;
    has name6 => \ sub { return ++$base };

    package main;
    my $cat = Cat->new;
    say $cat->name6->(); # 42
    say $cat->name6->(); # 43

=head2 tap

    $object = $object->tap( sub {...} );
    $object = $object->tap('some_method');
    $object = $object->tap( 'some_method', @args );

Tap into a method chain to perform operations on an object within the chain
(also known as a K combinator or Kestrel). The object will be the first argument
passed to the callback, and is also available as C<$_>. The callback's return
value will be ignored; instead, the object (the callback's first argument) will
be the return value. In this way, arbitrary code can be used within (i.e.,
spliced or tapped into) a chained set of object method calls.

    # longer version
    $object = $object->tap( sub { $_->some_method(@args) } );

    # inject side effects into a method chain
    $object->foo('A')->tap( sub { say $_->foo } )->foo('B');

=head2 with_roles

    my $new_class = SubClass->with_roles('SubClass::Role::One');
    my $new_class = SubClass->with_roles( '+One', '+Two' );
    $object       = $object->with_roles( '+One', '+Two' );

Create a new class with one or more L<Role::Tiny> roles. If called on a class
returns the new class, or if called on an object reblesses the object into the
new class. For roles following the naming scheme "MyClass::Role::RoleName" you
can use the shorthand "+RoleName".

    # create a new class with the role "SubClass::Role::Foo" and instantiate it
    my $new_class = SubClass->with_roles('+Foo');
    my $object    = $new_class->new;

You will almost certainly want to read the documentation for L<exact::role> for
writing roles.

=head1 SEE ALSO

You can look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/exact-class>

=item *

L<MetaCPAN|https://metacpan.org/pod/exact::class>

=item *

L<Travis CI|https://travis-ci.org/gryphonshafer/exact-class>

=item *

L<Coveralls|https://coveralls.io/r/gryphonshafer/exact-class>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/exact-class>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/D/exact-class.html>

=back

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Gryphon Shafer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
