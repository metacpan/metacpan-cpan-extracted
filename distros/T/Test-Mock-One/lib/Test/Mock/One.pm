package Test::Mock::One;
use warnings;
use strict;

# ABSTRACT: Mock the world with one object

our $VERSION = '0.008';

our $AUTOLOAD;

use overload '""' => '__x_mock_str';

use List::Util 1.33 qw(any);
use Scalar::Util qw(blessed);

sub new {
    my $class = shift;
    return bless({@_}, ref($class) || $class);
}

sub can {
    my ($self, $can) = @_;
    if (!exists $self->{$can} && $self->{"X-Mock-Strict"}) {
        return 0;
    }
    return 1;
}

sub AUTOLOAD {
    my $self = shift;

    my ($call) = $AUTOLOAD =~ /([^:]+)$/;

    if ($self->{'X-Mock-Called'}) {
        my @caller = caller(1); # who called the caller of self->$call
        push(@{ $self->{'X-Mock-Called-By'}{$caller[3]}{$call}}, [ @_ ]);
    }

    if (exists $self->{$call}) {
        my $ref = ref $self->{$call};
        if ($ref eq 'HASH') {
            return $self->new( __x_mock_copy_x($self), %{ $self->{$call} });
        }
        elsif ($ref eq 'ARRAY') {
            return $self->new(__x_mock_copy_x($self), map { $_ => $self } @{ $self->{$call} });
        }
        elsif ($ref eq 'CODE') {
            if ($self->{'X-Mock-SelfArg'}) {
                return $self->{$call}->($self, @_);
            }
            return $self->{$call}->(@_);
        }
        elsif ($ref eq 'REF') {
            return ${ $self->{$call} };
        }
        return $self->{$call};
    }
    elsif ($self->{"X-Mock-Strict"}) {
        die sprintf("Using %s in strict mode, called undefined function '%s'",
          __PACKAGE__, $call);
    }
    return $self;
}

sub isa {
    my ($self, $class) = @_;

    if (my $isas = $self->{"X-Mock-ISA"}) {
        my $ref = ref $isas;
        if (!$ref && $isas eq $class) {
            return 1;
        }
        elsif ($ref eq 'ARRAY') {
            return 1 if any { $_ eq $class } @$isas;
        }
        elsif ($ref eq 'CODE') {
            if ($self->{'X-Mock-SelfArg'}) {
                return $isas->($self, $class);
            }
            return $isas->($class);
        }
        elsif ($ref eq "Regexp") {
            return $class =~ /$isas/;
        }
        return 0;
    }
    elsif (exists $self->{"X-Mock-ISA"}) {
        return 0;
    }
    return 1;
}

# Just an empty method to prevent weird AUTOLOAD loops
sub DESTROY { }

my @__xattr = qw(Strict ISA Stringify SelfArg);

sub __x_mock_copy_x {
    my ($orig) = @_;
    my %copy;
    foreach (@__xattr) {
        my $attr = "X-Mock-$_";
        if (exists $orig->{$attr}) {
            $copy{$attr} = $orig->{$attr};
        }
    }
    return %copy;
}

sub __x_mock_str {
    my ($self) = @_;
    if (my $stringify = $self->{'X-Mock-Stringify'}) {
        if (ref $stringify eq 'CODE') {
            if ($self->{'X-Mock-SelfArg'}) {
                return $stringify->($self);
            }
            return $stringify->();
        }
        return $stringify;
    }
    return __PACKAGE__ . " stringified";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Mock::One - Mock the world with one object

=head1 VERSION

version 0.008

=head1 SYNOPSIS

    use Test::Mock::One;

    my $mock = Test::Mock::One->new(
        foo      => 'return value',
        bar      => 1,

        hashref  => \{ foo => 'bar' },
        arrayref => \[ foo => 'bar' ],
        code     => sub    { return your_special_function() },

    );

    $mock->foo;         # 'return value'
    $mock->bar;         # 1
    $mock->hashref;     # { foo => bar}
    $mock->arrayref;    # [ foo, bar ]
    $mock->code;        # executes your_special_function

    $mock->no->yes->work->it; # works fine

In combination with L<Sub::Override>:

    my $override = Sub::Override->new('Foo::Bar::baz', sub { Test::Mock::One(foo => 'bar') });

=head1 DESCRIPTION

Be able to mock many things with little code by using AUTOLOAD.

The problem this module tries to solve is to allow testing many things
without having to write many lines of code. If you want to create mock objects
you often need to write code like this:

    {
        no warnings qw(redefine once);
        local *Foo::thing = sub {
            return bless({}, 'Baz');
        };
        local *Baz::foo = sub { return 1 };
        local *Baz::bar = sub { return 1 };
        local *Baz::baz = sub { return 1 };
        use warnings;

        # Actual test here
    }

Test::Mock::One allows you to write a simple object that allows you to do the same with

    my $mock = Test::Mock::One->new(foo => 1, bar => 1, baz => 1);
    # Sub::Override helps too
    my $override = Sub::Override->new('Foo::thing' => sub { return $mock });

    # Actual test here

You don't actually need to define anything, by default method on a
Test::Mock::One object will return itself.  You can tweak the behaviour
by how you instantiate the object. There are several attributes that
control the object, these are defined as X-Mock attributes, see
L<Test::Mock::One/METHODS> for more on this.

=head2 Example

Let's say you want to test a function that retrieves a user from a
database and checks if it is active

    Package Foo;
    use Moose;

    has schema => (is => 'ro');

    sub check_user_in_db {
        my ($self, $username) = @_;
        my $user = $self->schema->resultset('User')->search_rs(
            { username => $username }
        )->first;

        return $user if $user && $user->is_active;
        die "Unable to find user";
    }

    # In your test
    my $foo = Foo->new(
        schema => Test::Mock::One->new(
            schema => {
                resultset =>
                    { search_rs => { first => { is_active => undef } } }
            },
            'X-Mock-Strict' => 1,
        )
    );

    # Is the same as above, without Strict mode
    $foo = Foo->new(
        schema => Test::Mock::One->new(
            is_active => undef
            # This doesn't work with X-Mock-Strict enabled, because
            # the chain schema->resultset->search_rs->first cannot be
            # resolved
        )
    );

    throws_ok(
        sub {
            $foo->check_user_in_db('username');
        },
        qr/Unable to find user/,
        "username isn't active"
    );

    # A sunny day scenario would have been:
    my $mock = Foo->new(schema => Test::Mock::One->new());
    lives_ok(sub { $mock->check_user_in_db('username') },
        "We found the user");

=head1 METHODS

=head2 new

Instantiate a new Test::Mock::One object

=over

=item X-Mock-Strict

Boolean value. Undefined attributes/methods will not be mocked and calling them makes us die.

=item X-Mock-ISA

Mock the ISA into the given class. Supported ways to mock the ISA:

    'X-Mock-ISA' => 'Some::Pkg',
    'X-Mock-ISA' => qr/Some::Pkg/,
    'X-Mock-ISA' => [qw(Some::Pkg Other::Pkg)],
    'X-Mock-ISA' => sub { return 0 },
    'X-Mock-ISA' => undef,

=item X-Mock-Stringify

Tell us how to stringify the object

    'X-Mock-Stringify' => 'My custom string',
    'X-Mock-Stringify' => sub { return "foo" },

=item X-Mock-Called

Boolean value. Allows mock object to keep caller information. See also L<Test::Mock::Two>.

=item X-Mock-SelfArg

Boolean value. Make all the code blocks use $self. This allows you to do things like

    Test::Mock::One->new(
        'X-Mock-SelfArg' => 1,
        code             => sub {
            my $self = shift;
            die "We have bar" if $self->foo eq 'bar';
            return "some value";
        }
    );

This also impacts C<X-Mock-ISA> and C<X-Mock-Stringify>.

=back

=head2 isa

Returns true or false, depending on how C<X-Mock-ISA> is set.

=head2 can

Returns true or false, depending on how C<X-Mock-Strict> is set.

=head1 SEE ALSO

=over

=item L<Test::Mock::Two>

=item L<Sub::Override>

=back

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
