package Var::Pairs;

our $VERSION = '0.003004';

use 5.014;
use warnings;
no if $] >= 5.018, warnings => "experimental::smartmatch";
use Carp;
use Devel::Callsite;

# Check for autoboxing, and set up pairs() method if applicable..
my $autoboxing;
BEGIN {
    if (eval{ require autobox }) {
        $autoboxing = 1;
        push @Var::Pairs::ISA, 'autobox';

        *Var::Pairs::autobox::pairs        = \&Var::Pairs::pairs;
        *Var::Pairs::autobox::kvs          = \&Var::Pairs::kvs;
        *Var::Pairs::autobox::each_pair    = \&Var::Pairs::each_pair;
        *Var::Pairs::autobox::each_kv      = \&Var::Pairs::each_kv;
        *Var::Pairs::autobox::invert       = \&Var::Pairs::invert;
        *Var::Pairs::autobox::invert_pairs = \&Var::Pairs::invert_pairs;
    }
}

# API...
my %EXPORTABLE;
@EXPORTABLE{qw< pairs kvs each_pair each_kv to_kv to_pair invert invert_pairs >} = ();

sub import {
    my ($class, @exports) = @_;

    # Check for export requests...
    if (!@exports) {
        @exports = keys %EXPORTABLE;
    }
    else {
        my @bad = grep { !exists $EXPORTABLE{$_} } @exports;
        carp 'Unknown subroutine' . (@bad==1 ? q{} : q{s})  . " requested: @bad"
            if @bad;
    }

    # Export API...
    no strict 'refs';
    my $caller = caller;
    for my $subname (@exports) {
        no strict 'refs';
        *{$caller.'::'.$subname} = \&{$subname};
    }

    # Enable autoboxing of ->pairs() in caller's lexical scope, if possible...
    if ($autoboxing) {
        $class->SUPER::import(
            HASH  => 'Var::Pairs::autobox',
            ARRAY => 'Var::Pairs::autobox',
        );
    }
}

# Track iterators for each call...
state %iterator_for;

# Convert one or more vars into a ('varname', $varname,...) list...

sub to_kv (\[$@%];\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]) {
    require PadWalker;

    # Grab caller vars...
    my ($lexvars, $packvars)  = (PadWalker::peek_my(1), PadWalker::peek_our(1));

    # Reverse them (creating addr --> name mapping)
    my %varname = (reverse(%$packvars), reverse(%$lexvars));

    # Remove the name sigils...
    s/^.// for values %varname;

    # Take each var ref and convert to 'name' => 'ref_or_val' pairs...
    return map { $varname{$_} => (ref($_) =~ /SCALAR|REF/ ? $$_ : $_) } @_;
}

# Convert one or more vars into 'varname' => $varname pairs...

sub to_pair (\[$@%];\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]) {
    require PadWalker;

    # Grab caller vars...
    my ($lexvars, $packvars)  = (PadWalker::peek_my(1), PadWalker::peek_our(1));

    # Reverse them (creating addr --> name mapping)
    my %varname = (reverse(%$packvars), reverse(%$lexvars));

    # Remove the name sigils...
    s/^.// for values %varname;

    # Take each var ref and convert to 'name' => 'ref_or_val' pairs...
    return map { Var::Pairs::Pair->new($varname{$_} => (ref($_) =~ /SCALAR|REF/ ? $$_ : $_), 'none') } @_;
}


# Generate pairs for iterating hashes and arrays...
sub pairs (+) {
    if (!defined wantarray) {
        croak("Useless use of pairs() in void context");
    }
    elsif (!wantarray) {
        croak("Invalid call to pairs() in scalar context.\nDid you mean each_pair()?\nError")
    }

    my $container_ref = shift;
    my $container_type = ref $container_ref || 'scalar value';

    # Verify the single argument...
    if ($container_type !~ m{^ARRAY$|^HASH$}) {
        croak "Argument to pairs() must be array or hash (not \L$container_type\E)";
    }

    # Uniquely identify this call, according to its lexical context...
    my $ID = callsite() . context() . $container_ref;

    # Short-circuit if this is a repeated call...
    if (!wantarray && $iterator_for{$ID}) {
        return _get_each_pair($ID);
    }

    # Generate the list of pairs, according to the container type...
    my $container_is_array = $container_type eq 'ARRAY';
    my @pairs = map { Var::Pairs::Pair->new($_, $container_ref, $container_is_array ? 'array' : 'hash') }
                    $container_is_array ? 0..$#{$container_ref} : keys %{$container_ref};

    # Return them all in list context...
    return @pairs;

    # In scalar context, return the first pair, remembering the rest...
    $iterator_for{$ID} = \@pairs;
    return shift @pairs;
}

sub each_pair (+) {
    my ($container_ref) = @_;

    # Uniquely identify this call, according to its lexical context...
    my $ID = callsite() . context() . $container_ref;

    # Build an iterator...
    $iterator_for{$ID} //= [ &pairs ];

    # Iterate...
    return _get_each_pair($ID);
}

# Generate key, value,... lists for iterating hashes and arrays...
sub kvs (+) {
    if (!defined wantarray) {
        croak("Useless use of kvs() in void context");
    }
    elsif (!wantarray) {
        croak("Invalid call to kvs() in scalar context.\nDid you mean each_kv()?\nError")
    }

    my $container_ref = shift;
    my $container_type = ref $container_ref || 'scalar value';

    # Verify the single argument...
    if ($container_type !~ m{^ARRAY$|^HASH$}) {
        croak "Argument to pairs() must be array or hash (not \L$container_type\E)";
    }

    # Uniquely identify this call, according to its lexical context...
    my $ID = callsite() . context() . $container_ref;

    # Return the key/value list, according to the container type...
    if ($container_type eq 'ARRAY') {
        return map { ($_, $container_ref->[$_]) } 0..$#{$container_ref};
    }
    else {
        return %{$container_ref};
    }
}

sub each_kv (+) {
    my ($container_ref) = @_;

    # Uniquely identify this call, according to its lexical context and iteration target...
    my $ID = callsite() . context() . $container_ref;

    # Build an iterator...
    $iterator_for{$ID} //= [ &kvs ];

    # Iterate...
    return _get_each_kv($ID);
}



# Invert the key=>values of a hash or array...

sub invert (+) {
    goto &_invert;
}

sub invert_pairs (+) {
    push @_, 1;
    goto &_invert;
}


# Utilities...

# Perform var inversions...

sub _invert {
    my ($var_ref, $return_as_pairs) = @_;
    my %inversion;

    if (!defined wantarray) {
        croak 'Useless use of invert() in void context';
    }
    elsif (!wantarray) {
        croak 'Invalid call to invert() in scalar context';
    }

    given (ref($var_ref) || 'SCALAR') {
        when ('HASH') {
            for my $key (keys %{$var_ref}) {
                my $values = $var_ref->{$key};
                for my $value ( ref $values eq 'ARRAY' ? @$values : $values ) {
                    $inversion{$value} //= [];
                    push @{$inversion{$value}}, $key;
                }
            }
        }
        when ('ARRAY') {
            for my $key (0..$#{$var_ref}) {
                my $values = $var_ref->[$key];
                for my $value ( ref $values eq 'ARRAY' ? @$values : $values ) {
                    $inversion{$value} //= [];
                    push @{$inversion{$value}}, $key;
                }
            }
        }
        default {
            croak "Argument to invert() must be hash or array (not \L$_\E)";
        }
    }

    return $return_as_pairs ? pairs %inversion : %inversion;
}

# Iterate, cleaning up if appropriate...
sub _get_each_pair {
    my $ID = shift;

    # Iterator the requested iterator...
    my $each_pair = shift @{$iterator_for{$ID}};

    # If nothing was left to iterate, clean up the empty iterator...
    if (!defined $each_pair) {
        delete $iterator_for{$ID};
    }

    return $each_pair;
}

sub _get_each_kv {
    my $ID = shift;

    # Iterator the requested iterator...
    my @each_kv = splice @{$iterator_for{$ID}}, 0, 2;

    # If nothing was left to iterate, clean up the empty iterator...
    if (!@each_kv) {
        delete $iterator_for{$ID};
    }

    # Return key or key/value, as appropriate (a la each())...
    return wantarray ? @each_kv : $each_kv[0];
}

use if $] <  5.022, 'Var::Pairs::Pair_DataAlias';
use if $] >= 5.022, 'Var::Pairs::Pair_BuiltIn';

1; # Magic true value required at end of module
__END__


=head1 NAME

Var::Pairs - OO iterators and pair constructors for variables


=head1 VERSION

This document describes Var::Pairs version 0.003004


=head1 SYNOPSIS

    use Var::Pairs;

    # pairs() lists all OO pairs from arrays and hashes...

    for my $next (pairs @array) {
        say $next->index, ' has the value ', $next->value;
    }


    # each_pair() iterates OO pairs from arrays and hashes...

    while (my $next = each_pair %hash) {
        say $next->key, ' had the value ', $next->value;
        $next->value++;
    }


    # to_kv() converts vars into var_name => var_value pairs...

    Sub::Install::install_sub({to_kv $code, $from, $into});


    # invert() reverses a one-to-many mapping correctly...

    my %reverse_mapping = invert %mapping;

    my %reverse_lookup  = invert @data;


=head1 DESCRIPTION

This module exports a small number of subroutines that
add some Perl 6 conveniences to Perl 5. Specifically,
the module exports several subroutines that simplify
interactions with key/value pairs in hashes and arrays.



=head1 INTERFACE

=head2 Array and hash iterators

=over

=item C<pairs %hash>

=item C<pairs @array>

=item C<pairs $hash_or_array_ref>

In list context, C<pairs()> returns a list of "pair" objects, each of
which contains one key/index and value from the argument.
In scalar and void contexts, C<pairs()> throws an exception.

The typical list usage is:

    for my $pair (pairs %container) {
        # ...do something with $pair
    }


The intent is to provide a safe and reliable replacement for the
built-in C<each()> function; specifically, a replacement that can be
used in C<for> loops.

=back

=over

=item C<kvs %hash>

=item C<kvs @array>

=item C<kvs $hash_or_array_ref>

In list context, C<kvs()> returns a list of alternating keys and values.
That is C<kvs %hash> flattens the hash to C<(I<key>, I<value>, I<key>, I<value>...)>
and C<kvs @array> flattens the array to C<(I<index>, I<value>, I<index>,
I<value>...)>.

In scalar and void contexts, C<kvs()> throws an exception.

The most typical use is to populate a hash from an array:

    my %hash = kvs @array;

    # does the same as:

    my %hash; @hash{0..$#array} = @array;

=back

=over

=item C<each_pair %hash>

=item C<each_pair @array>

=item C<each_pair $hash_or_array_ref>

In all contexts, C<each_pair()> returns a single "pair" object,
containing the key/index and value of the next element in the argument.

A separate internal iterator is created for each call to C<each_pair()>, so
multiple calls to C<each_pair()> on the same container variable can be
nested without interacting with each other (i.e. unlike multiple calls
to C<each()>).

When the iterator is exhausted, the next call to C<each_pair()> returns
C<undef> or an empty list (depending on context), and resets the iterator.

The typical usage is:

    while (my $pair = each_pair %container) {
        # ...do something with $pair->key and $pair->value
    }

Note, however, that using C<pairs()> in a C<for> loop is
the preferred idiom:

    for my $pair (pairs %container) {
        # ...do something with $pair->key and $pair->value
    }

=back

=over

=item C<each_kv %hash>

=item C<each_kv @array>

=item C<each_kv $hash_or_array_ref>

In list contexts, C<each_kv()> returns a list of two elements: the
key/index and the value of the next element in the argument.
In scalar contexts, just the next key is returned.

As with C<each_pair()>, a separate internal iterator is created for each
call to C<each_kv()>, so multiple calls to C<each_kv()> on the same
container variable can be nested without interacting with each other
(i.e. unlike multiple calls to C<each()>).

When the iterator is exhausted, the next call to C<each_kv()> returns
C<undef> in scalar context or an empty list in list context, and resets
the iterator.

The typical list usage is:

    while (my ($key1, $val1) = each_kv %container) {
        while (my ($key2, $val2) = each_kv %container) {
            # ...do something with the two keys and two values
        }
    }

The typical scalar usage is:

    while (my $key1 = each_kv %container) {
        while (my $key2 = each_kv %container) {
            # ...do something with the two keys
        }
    }

In other words, C<each_kv()> is a drop-in replacement for Perl's
built-in C<each()>, with two exceptions: one an advantage, the other a
limitation. The advantage is that you can nest C<each_kv()> iterations
over the same variable without shooting yourself in the foot. The
limitation is that, unlike C<each()>, C<each_kv()> does not reset
when you call the C<keys> function on the hash you're iterating.

=back

=over

=item C<< %hash->pairs >>

=item C<< @array->pairs >>

=item C<< $hash_or_array_ref->pairs >>

=item C<< %hash->kvs >>

=item C<< @array->kvs >>

=item C<< $hash_or_array_ref->kvs >>

=item C<< %hash->each_pair >>

=item C<< @array->each_pair >>

=item C<< $hash_or_array_ref->each_pair >>

=item C<< %hash->each_kv >>

=item C<< @array->each_kv >>

=item C<< $hash_or_array_ref->each_kv >>

If you have the C<autobox> module installed, you can use this OO syntax
as well. Apart from their call syntax, these OO forms are exactly the
same as the subroutine-based interface described above.

=back

=head2 Pairs

=over

=item C<< $pair->key >>

Returns a copy of the key of the pair,
if the pair was derived from a hash.
Returns a copy of the index of the pair,
if the pair was derived from an array.


=item C<< $pair->index >>

Nothing but a synonym for C<< $pair->key >>. Use whichever suits your
purpose, your program, or your predilections.


=item C<< $pair->value >>

Returns the value of the pair, as an lvalue.
That is:

    for my $item (pairs %items) {
        say $item->value
            if $item->key =~ /\d/;
    }

will print the value of every entry in the C<%items> hash
whose key includes a digit.

And:

    for my $item (pairs %items) {
        $item->value++;
            if $item->key =~ /^Q/;
    }

will increment each value in the C<%items> hash
whose key starts with 'Q'.


=item C<< $pair->kv >>

Returns a two-element list containing copies of the key and the value of
the pair. That is:

    for my $item (pairs %items) {
        my ($k, $v) = $item->kv;
        say $v
            if $k =~ /\d/;
    }

will print the value of every entry in the C<%items> hash
whose key includes a digit.


=item C<< "$pair" >>

When used as a string, a pair is converted to a suitable representation
for a pair, namely: C<< "I<key> => I<value>" >>


=item C<< 0 + $pair >>

Pairs cannot be used as numbers: an exception is thrown.


=item C<< if ($pair) {...} >>

When a pair is used as a boolean, it is always true.

=back


=head2 Named pair constructors

=over

=item C<< to_pair $scalar, @array, %hash, $etc >>

The C<to_pair> subroutine takes one or more variables and converts each of them
to a single Pair object. The Pair's key is the name of the variable
(minus its leading sigil), and the value is the value of the variable
(if it's a scalar) or a reference to the variable (if it's an array or hash).

That is:

    to_pair $scalar, @array, %hash, $etc

is equivalent to:

    Pair->new( scalar =>  $scalar ),
    Pair->new( array  => \@array  ),
    Pair->new( hash   => \%hash   ),
    Pair->new( etc    =>  $etc    )

This is especially useful for generating modern sets of named arguments
for other subroutines. For example:

    Sub::Install::install_sub(to_pair $code, $from, $into);

instead of:

    Sub::Install::install_sub(
        Pair->new(code => $code),
        Pair->new(from => $from),
        Pair->new(into => $into)
    );


=item C<< to_kv $scalar, @array, %hash, $etc >>

The C<to_kv()> subroutine takes one or more variables and converts each of them
to a I<key> C<< => >> I<value> sequence (i.e. a two-element list, rather than
a Pair object).

As with C<to_pair()>, the key is the name of the variable (minus its
leading sigil), and the value is the value of the variable (if it's a
scalar) or a reference to the variable (if it's an array or hash).

That is:

    to_kv $scalar, @array, %hash, $etc

is equivalent to:

    scalar => $scalar, array => \@array, hash => \%hash, etc => $etc

This is especially useful for generating traditional sets of named
arguments for other subroutines. For example:

    Sub::Install::install_sub({to_kv $code, $from, $into});

instead of:

    Sub::Install::install_sub({code => $code, from => $from, into => $into});

=back


=head2 Array and hash inverters

=over

=item C<< invert %hash >>

=item C<< invert @array >>

=item C<< invert $hash_or_array_ref >>

The C<invert> subroutine takes a single hash or array (or a reference to
either) and returns a list of alternating keys and value, where each key
is a value from the original variable and each corresponding value is a
reference to an array containing the original key(s). This list is typically
used to initialize a second hash, which can then be used as a reverse mapping.
In other words:

    my %hash = ( a => 1, b => 2, c => 1, d => 1, e => 2, f => 3 );

    my %inversion = invert %hash;

is equivalent to:

    my %inversion = (
        1 => ['a', 'c', 'd'],
        2 => ['b', 'e'],
        3 => ['f'],
    );

C<invert> correctly handles the many-to-many case where some of the values in
the original are array references. For example:

    my %hash = ( a => [1,2], b => 2, c => [1,3], d => 1, e => [3,2], f => 3 );

    my %inversion = invert %hash;

is equivalent to:

    my %inversion = (
        1 => ['a', 'c', 'd'],
        2 => ['a', 'b', 'e'],
        3 => ['c', 'e', 'f'],
    );


=item C<< invert_pairs %hash >>

=item C<< invert_pairs @array >>

=item C<< invert_pairs $hash_or_array_ref >>

C<invert_pairs()> acts exactly like C<invert()>, except that it returns
a list of Pair objects (like C<pairs()> does).

This is not useful for initializing other hashes, but is handy for debugging
a reverse mapping:

    say for invert_pairs %hash;



=item C<< %hash->invert >> or C<< %hash->invert_pairs >>

=item C<< @array->invert >> or C<< @array->invert_pairs >>

=item C<< $hash_or_array_ref->invert >> or C<< $hash_or_array_ref->invert_pairs >>

If you have the C<autobox> module installed, you can use this OO syntax
as well. Apart from their call syntax, these OO forms are exactly the
same as the subroutine-based interfaces described above.

=back


=head1 DIAGNOSTICS

=over

=item C<< Argument to %s must be hash or array (not %s) >>

Except for C<to_pair()> and C<to_kv()>, all of the subroutines exported
by this module only operate on hashes, arrays, or references to hashes
or arrays. Asking for the "pairs" insidde a scalar, typeglob, or other entity
is meaningless; they're simply not structured as collections of keyed values.


=item C<< Useless use of pairs() in void context >>

=item C<< Useless use of kvs() in void context >>

=item C<< Useless use of invert() in void context >>

None of these subroutines has any side-effects, so calling them in void
context is a waste of time.

=item C<< Invalid call to pairs() in scalar context >>

=item C<< Invalid call to kvs() in scalar context >>

=item C<< Invalid call to invert() in scalar context >>

All these subroutines return a list, so in scalar context you just
get a count (which there are cheaper and easier ways to obtain).

The most common case where this error is reported is when C<pairs()> or
C<kvs()> is used in a C<while> loop, instead of a C<for> loop. Either
change the type of loop, or else use C<each_pair()> or C<each_kv()>
instead.

=item C<< Can't convert Pair(%s => %s) to a number >>

You attempted to use one of the pair objects returned by C<pairs()>
as a number, but the module has no idea how to do that.

You probably need to use C<< $pair->index >> or C<< $pair->value >> instead.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Var::Pairs requires no configuration files or environment variables.


=head1 DEPENDENCIES

The module requires Perl 5.014 and the following modules:

=over

=item Perl 5.14 or later

=item Devel::Callsite

=item Data::Alias (under Perl 5.20 and earlier)

=item PadWalker

=back

To use the optional C<< $container->pairs >> syntax,
you also need the C<autobox> module.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-var-pairs@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

C<each_kv()> acts like a true one-time only iterator (in the OO sense),
so there is no way to reset its iteration (i.e. the way that calling
C<keys()> on a hash or array, resets any C<each()> that is iterating
it). If you need to reset partially iterated hashes or arrays, you will
need to use some other mechanism to do so.


=head1 ACKNOWLEDGEMENTS

Based on a suggestion by Karl Brodowsky
and inspired by several features of Perl 6.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
