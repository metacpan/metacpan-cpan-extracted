package Test::Mock::One;
use warnings;
use strict;

# ABSTRACT: Mock the world with one object

our $VERSION = '0.005';

our $AUTOLOAD;

use overload '""' => '_stringify';

use List::Util 1.33 qw(any);
use Scalar::Util qw(blessed);

sub new {
    my $class = shift;
    return bless({@_}, ref($class) || $class);
}

my @__xattr = qw(Strict ISA Stringify);

sub __copy_xattr {
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

sub AUTOLOAD {
    my $self = shift;

    my ($call) = $AUTOLOAD =~ /([^:]+)$/;

    if (exists $self->{$call}) {
        my $ref = ref $self->{$call};
        if ($ref eq 'HASH') {
            return $self->new( __copy_xattr($self), %{ $self->{$call} });
        }
        elsif ($ref eq 'ARRAY') {
            return $self->new(__copy_xattr($self), map { $_ => $self } @{ $self->{$call} });
        }
        elsif ($ref eq 'CODE') {
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



sub _stringify {
    my ($self) = @_;
    if (my $stringify = $self->{'X-Mock-Stringify'}) {
        return ref $stringify eq 'CODE' ? $stringify->() : $stringify;
    }
    return __PACKAGE__ . " stringified";
}

# Just an empty method to prevent weird AUTOLOAD loops
sub DESTROY { }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Mock::One - Mock the world with one object

=head1 VERSION

version 0.005

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

In combination with Sub::Override

    my $override = Sub::Override->new('Foo::Bar::baz', sub { Test::Mock::One(foo => 'bar') });

You now have Foo::Bar::baz that returns an object where the function foo returns bar.

Let's say you want to test a function that retrieves a user from a database and checks if it is active

    Package Foo;
    use Moose;

    has schema => ( is => 'ro' );
    sub check_user_in_db {
        my ($self, $username) = @_;
        my $user = $self->schema->resultset('User')->search_rs({username => $username})->first;
        return $user if $user->is_active;
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
    lives_ok(sub { $mock->check_user_in_db('username')}, "We found the user");

=head1 DESCRIPTION

Be able to mock many things with little code by using AUTOLOAD.

The problem this module tries to solve is to allow testing many things
without having to write a monkey patch kind of solution in your test.
Test::Mock::One tries to solve this by creating an object that can do
"everything", and allows you to control specific behaviour. It works
really well in combination with L<Sub::Override>.

The methods copy the X-Mock attributes from their parent to themselves.

=head1 METHODS

=head2 new

Ways to override specific behaviours

=over

=item X-Mock-Strict

Boolean value. Undefined attributes will not be mocked and calling them makes us die.

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

=back

=head2 isa

Returns true or false, depending on how X-Mock-Strict is set.

=head1 SEE ALSO

L<Sub::Override>

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
