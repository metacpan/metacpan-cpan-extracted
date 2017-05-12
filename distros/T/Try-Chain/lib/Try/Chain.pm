package Try::Chain; ## no critic (TidyCode)

use strict;
use warnings;
use parent qw(Exporter);
use Try::Tiny qw(try catch finally);

our $VERSION = '0.005';

our @EXPORT_OK = qw(
    try catch finally
    try_chain
    $call_m  $call_em
    $fetch_i $fetch_ei
    $fetch_k $fetch_ek
);

sub try_chain (&;@) { ## no critic (SubroutinePrototypes)
    my ( $chain_code, @more ) = @_;

    my $check_code = sub {
        ## no critic (ComplexRegexes)
        m{
            \A \QCan't call method "\E .*? \Q" on an undefined value\E \b
            | \A \QCan't locate object method "\E .*? \Q" via package\E \b
            | \A \QCan't use an undefined value as a HASH reference\E \b
            | \A \QCan't use an undefined value as an ARRAY reference\E \b
        }xms
            or die $_; ## no critic (RequireCarping)
        ## use critic (ComplexRegexes)

        return ();
    };

    return @more
        ? try {
            try { $chain_code->() } catch { $check_code->() };
        } @more
        : try { $chain_code->() } catch { $check_code->() };
}

our $call_m = sub { ## no critic (PackageVars)
    my ( $self, $method, @more ) = @_;

    return $self ? $self->$method(@more) : ();
};

our $call_em = sub { ## no critic (PackageVars)
    my ( $self, $method, @more ) = @_;

    return $self && $self->can($method) ? $self->$method(@more) : ();
};

our $fetch_i = sub { ## no critic (PackageVars)
    my ( $array_ref, $index ) = @_;

    return $array_ref->[$index];
};
our $fetch_ei = sub { ## no critic (PackageVars)
    my ( $array_ref, $index ) = @_;

    return exists $array_ref->[$index] ? $array_ref->[$index] : undef;
};

our $fetch_k = sub { ## no critic (PackageVars)
    my ( $hash_ref, $key ) = @_;

    return $hash_ref->{$key};
};
our $fetch_ek = sub { ## no critic (PackageVars)
    my ( $hash_ref, $key ) = @_;

    return exists $hash_ref->{$key} ? $hash_ref->{$key} : undef;
};

# $Id$

1;

__END__

=head1 NAME

Try::Chain - Call method, hash and/or array chains with break on undef

=head1 VERSION

0.005

=head1 SYNOPSIS

The module exports:

=over

=item try

imported from Try::Tiny

=item catch

imported from Try::Tiny

=item finally

imported from Try::Tiny

=item try_chain

implemented here to call a complete chain or break

=item $call_m

implemented here to call a method or break

=item $call_em

implemented here to call an existing method or break

=item $fetch_i

implemented here to fetch an array index or break

=item $fetch_ei

implemented here to fetch an existing array index or break

=item $fetch_k

implemented here to fetch a hash key or break

=item $fetch_ek

implemented here to fetch an existing hash key or break

=back

Import what needed. The following code describes the full import:

    use Try::Chain qw(
        try catch finally
        try_chain
        $call_m  $call_em
        $fetch_i $fetch_ei
        $fetch_k $fetch_ek
    );

=head1 EXAMPLE

Inside of this Distribution is a directory named example.
Run this *.pl files.

=head1 DESCRIPTION

Call method, hash and/or array chains with break on undef means,
that in some cases it is ok to get back nothing late or early.

=head2 Problem

In case of method chain like

    my $scalar = $obj->foo(1)->bar(2)->baz(3);

    my %hash = (
        any => 'any',
        baz => scalar $obj->foo(1)->bar(2)->baz(3),
    );

and foo or bar can return nothing or undef, you get an error:
Can't call method ... on an undefined value.

A quick solution is:

    my $scalar
        = $obj->foo(1)
        && $obj->foo(1)->bar(2)
        && $obj->foo(1)->bar(2)->baz(3);

    my %hash = (
        any => 'any',
        baz => scalar $obj->foo(1)
               && $obj->foo(1)->bar(2)
               && $obj->foo(1)->bar(2)->baz(3),
    );

In case of method foo and/or bar is performance critical code
it is a bad idea to call the method code more then one time.
The the solution looks like this:

    my $foo    = $obj->foo(1);
    my $bar    = $foo && $foo->bar(2);
    my $scalar = $bar && $bar->baz(3);

    my %hash = (
        any => 'any',
        baz => do {
            my $foo = $obj->foo(1);
            my $bar = $foo && $foo->bar(2);
            $bar && scalar $bar->baz(3);
        },
    );

=head2 Solution

This module allows to call the chain by ignoring all undef errors in block:

    my $scalar = try_chain { $obj->foo(1)->bar(2)->baz(3) };

    my %hash = (
        any => 'any',
        baz => scalar try_chain { $obj->foo(1)->bar(2)->baz(3) },
    );

Or better step by step?

    my $scalar = $obj->$call_m('foo', 1)->$call_m('bar', 2)->$call_m('baz', 3);

    my %hash = (
        any => 'any',
        baz => scalar $obj
            ->$call_m('foo', 1)
            ->$call_m('bar', 2)
            ->$call_m('baz', 3),
    );

Also possible with maybe not existing hash or array references:

    ... = try_chain { $any->foo->[0]->bar(@params)->{key}->baz };

Or better step by step?

    ... = $any
        ->$call_m('foo')
        ->$fetch_i(0)
        ->$call_m(bar => @params)
        ->$fetch_k('key')
        ->$call_m('baz');

Full Try::Tiny support:

    ... = try_chain { ... } catch { ... } finally { ... };

=head2 Solution for the autovivification problem

Switch off possible autovivication:

    $result = try_chain {
        no autovivification;
        $any->foo->{key}->bar(@params)->[0]->baz;
    };

    @result = try_chain {
        no autovivification;
        $any->foo->{key}->bar(@params)->[0]->baz;
    };

=head1 SUBROUTINES/METHODS

=head2 sub try_chain

Calls the whole try block, breaks and ignores undef errors.

=head2 sub $call_m

Calls the next method if possible.

=head2 sub $call_em

Calls the next method if possible and method exists.

=head2 sub $fetch_i

Calls the next index of an array reference if possible.

=head2 sub $fetch_ei

Calls the next index of an array reference if possible and index exists.

=head2 sub $fetch_k

Calls the next key of a hash reference if possible.

=head2 sub $fetch_ek

Calls the next key of a hash reference if possible and key exists.

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

nothing

=head1 DEPENDENCIES

L<parent|parent>

L<Exporter|Exporter>

L<Try::Tiny|Try::Tiny>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

none

=head1 SEE ALSO

L<Try::Tiny|Try::Tiny>

L<autovivification|autovivification>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2017,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
