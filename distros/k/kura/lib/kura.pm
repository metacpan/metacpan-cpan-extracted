package kura;
use strict;
use warnings;

our $VERSION = "0.03";

use Carp ();
use Sub::Util ();
use Scalar::Util ();

my %FORBIDDEN_NAME = map { $_ => 1 } qw{
    BEGIN CHECK DESTROY END INIT UNITCHECK
    AUTOLOAD STDIN STDOUT STDERR ARGV ARGVOUT ENV INC SIG
};

# This is a default Exporter class.
# You can change this class by setting $kura::EXPORTER_CLASS.
our $EXPORTER_CLASS = 'Exporter';

# This is a default constraint code to object.
# You can change this code by setting $kura::CALLABLE_TO_OBJECT.
#
# NOTE: This variable will probably change. Use caution when overriding it.
our $CALLABLE_TO_OBJECT = sub {
    my ($name, $constraint, $caller) = @_;

    require Type::Tiny;
    Type::Tiny->new(
        constraint => $constraint,
    );
};

sub import {
    my $pkg = shift;
    my $caller = caller;

    $pkg->import_into($caller, @_);
}

sub import_into {
    my $pkg = shift;
    my ($caller, $name, $constraint) = @_;

    my $err;

    $err = _validate_name($name);
    Carp::croak $err if $err;

    $err = _validate_constraint($constraint);
    Carp::croak $err if $err;

    $err = _install_constraint($name, $constraint, $caller);
    Carp::croak $err if $err;

    $err = _setup_exporter($caller);
    Carp::croak $err if $err;
}

sub _validate_name {
    my ($name) = @_;

    if (!defined $name) {
        return 'name is required';
    }
    elsif ($FORBIDDEN_NAME{$name}) {
        return "'$name' is forbidden.";
    }
    return;
}

sub _validate_constraint {
    my ($constraint) = @_;

    unless (defined $constraint) {
        return 'constraint is required';
    }

    return if Scalar::Util::blessed($constraint) && $constraint->can('check');

    my $ref = Scalar::Util::reftype($constraint) // '';

    return if $ref eq 'CODE';

    return "Invalid constraint. It must be an object that has a 'check' method or a code reference.";
}

sub _constraint_to_code {
    my ($name, $constraint, $caller) = @_;

    if (Scalar::Util::reftype($constraint) eq 'CODE') {
        $constraint = $CALLABLE_TO_OBJECT->($name, $constraint, $caller);
    }

    sub { $constraint };
}

sub _install_constraint {
    my ($name, $constraint, $caller) = @_;

    if ($caller->can($name)) {
        return "'$name' is already defined";
    }

    my $code = _constraint_to_code(@_);

    {
        no strict "refs";
        *{"$caller\::$name"} = Sub::Util::set_subname( "$caller\::$name", $code);
        push @{"$caller\::EXPORT_OK"}, $name;
    }

    return;
}

sub _setup_exporter {
    my ($caller) = @_;

    my $exporter_class = $EXPORTER_CLASS;

    unless ($caller->isa($exporter_class)) {
        no strict "refs";
        push @{ "$caller\::ISA" }, $exporter_class;
        ( my $file = $caller ) =~ s{::}{/}g;
        $INC{"$file.pm"} ||= __FILE__;
    }

    return;
}

1;
__END__

=encoding utf-8

=head1 NAME

kura - Store constraints for Data::Checks, Type::Tiny, Moose and more.

=head1 SYNOPSIS

    package MyFoo {
        use Data::Checks qw(StrEq);
        use kura Foo => StrEq('foo');
    }

    package MyBar {
        use Types::Standard -types;
        use kura Bar => Str & sub { $_[0] eq 'bar' };
    }

    package MyBaz {
        use Moose::Util::TypeConstraints;
        use kura Baz => subtype as 'Str' => where { $_[0] eq 'baz' };
    }

    package MyQux {
        use kura Qux => sub { $_[0] eq 'qux' };
    }

    use MyFoo qw(Foo);
    use MyBar qw(Bar);
    use MyBaz qw(Baz);
    use MyQux qw(Qux); # CodeRef converted to Type::Tiny

    ok  Foo->check('foo') && !Foo->check('bar') && !Foo->check('baz') && !Foo->check('qux');
    ok !Bar->check('foo') &&  Bar->check('bar') && !Bar->check('baz') && !Bar->check('qux');
    ok !Baz->check('foo') && !Baz->check('bar') &&  Baz->check('baz') && !Baz->check('qux');
    ok !Qux->check('foo') && !Qux->check('bar') && !Qux->check('baz') &&  Qux->check('qux');

=head1 DESCRIPTION

Kura - means "Traditional Japanese storehouse" - stores constraints, such as L<Data::Checks>, L<Type::Tiny>, L<Moose::Meta::TypeConstraint>, L<Mouse::Meta::TypeConstraint>, L<Specio> and more. It can even be used with L<Moo> when combined with L<Type::Tiny> constraints.

    Data::Checks -----------------> +--------+
                                    |        |
    Type::Tiny -------------------> |        |
                                    |  Kura  | ---> Named Value Constraints!
    Moose::Meta::TypeConstraint --> |        |
                                    |        |
    YourFavoriteConstraint -------> +--------+

If your project uses multiple constraint libraries, kura allows you to simplify your codes and making it easier to manage different constraint systems. This is especially useful in large projects or when migrating from one constraint system to another.

=head1 HOW TO USE

=head2 Declaring a constraint

It's easy to use to store constraints in a package:

    use kura NAME => CONSTRAINT;

This constraint must be a any object that has a C<check> method or a code reference that returns true or false.
The following is an example of a constraint declaration:

    # use Type::Tiny
    use Types::Standard -types;

    use kura Name  => Str & sub { qr/^[A-Z][a-z]+$/ };
    use kura Level => Int & sub { $_[0] >= 1 && $_[0] <= 100 };

    use kura Charactor => Dict[
        name  => Name,
        level => Level,
    ];

When declaring constraints, it is important to define child constraints before their parent constraints to avoid errors. For example:

    # Bad order
    use kura Parent => Dict[ name => Child ]; # => Bareword "Child" not allowed
    use kura Child => Str;

    # Good order
    use kura Child => Str;
    use kura Parent => Dict[ name => Child ];

If constraints are declared in the wrong order, you might encounter errors like “Bareword not allowed.” Ensure that all dependencies are declared beforehand to prevent such issues.

=head2 Using a constraint

You can use the declared constraint as follows:

    package MyFoo {
        use Data::Checks qw(StrEq);
        use kura Foo => StrEq('foo');
    }

    use MyFoo qw(Foo);
    Foo->check('foo'); # true

Internally, Kura inherits L<Exporter> and automatically adds the declared constraint to C<@EXPORT_OK>:

    MyFoo->isa('Exporter'); # true
    @MyFoo::EXPORT_OK; # ('Foo')

So, you can add other functions to C<@EXPORT_OK>:

    package MyFoo {
        our @EXPORT_OK;
        push @EXPORT_OK => qw(hello);

        use kura Foo => sub { $_[0] eq 'foo' };

        sub hello { 'Hello, World!' }
   }

   use MyFoo qw(Foo hello);
   hello(); # 'Hello, World!'

=head1 Customizing

=head2 C<$EXPORTER_CLASS>

C<$EXPORTER_CLASS> is a package name of the Exporter class, default is L<Exporter>.
You can change this class by setting C<$kura::EXPORTER_CLASS>.

    package mykura {
        use kura ();

        sub import {
            my $pkg = shift;
            my $caller = caller;

            local $kura::EXPORTER_CLASS = 'Exporter::Tiny';
            kura->import_into($caller, @_);
        }
    }

    package MyFoo {
        use mykura Foo => sub { $_[0] eq 'foo' };
    }

    # Exporter::Tiny accepts the `-as` option
    use MyFoo Foo => { -as => 'CheckerFoo' };

    CheckerFoo->check('foo'); # true

=head1 LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kobaken E<lt>kentafly88@gmail.comE<gt>

=cut

