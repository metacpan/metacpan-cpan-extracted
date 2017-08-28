###############################################################################
#
# This file copyright © 2016 by Randy J. Ray, all rights reserved
#
# See "LICENSE AND COPYRIGHT" in the POD for terms.
#
###############################################################################
#
#   Description:    A string-formatter inspired by Python's format()
#
#   Functions:      YASF
#                   new
#                   bind
#                   format
#
#   Libraries:      None (only core)
#
#   Global Consts:  @EXPORT_OK
#                   %NOT_ACCEPTABLE_REF
#
#   Environment:    None
#
###############################################################################

package YASF;

use 5.008;
use strict;
use warnings;
use overload fallback => 0,
    'eq'  => \&_eq,
    'ne'  => \&_ne,
    'lt'  => \&_lt,
    'le'  => \&_le,
    'gt'  => \&_gt,
    'ge'  => \&_ge,
    'cmp' => \&_cmp,
    q{.}  => \&_dot,
    q{.=} => \&_dotequal,
    q{""} => \&_stringify,
    q{%}  => \&_interpolate;

use Carp qw(carp croak);
use Exporter qw(import);

our $VERSION = '0.005'; # VERSION

BEGIN {
    no strict 'refs'; ## no critic (ProhibitNoStrict)

    for my $method (qw(template bindings on_undef)) {
        *{$method} = sub { shift->{$method} }
    }
}

my %NOT_ACCEPTABLE_REF = (
    SCALAR  => 1,
    CODE    => 1,
    REF     => 1,
    GLOB    => 1,
    LVALUE  => 1,
    FORMAT  => 1,
    IO      => 1,
    VSTRING => 1,
    Regexp  => 1,
);

my %VALID_ON_UNDEF = (
    die    => 1,
    warn   => 1,
    token  => 1,
    ignore => 1,
);

our @EXPORT_OK = qw(YASF);

###############################################################################
#
#   Sub Name:       YASF
#
#   Description:    Shortcut to calling YASF->new($str) with no other args.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $template in      scalar    String template for formatter
#
#   Returns:        Success:    new object
#                   Failure:    dies
#
###############################################################################
## no critic(ProhibitSubroutinePrototypes)
sub YASF ($) { return YASF->new(shift); }

###############################################################################
#
#   Sub Name:       new
#
#   Description:    Class constructor. Creates the basic object and
#                   pre-compiles the template into the form that the formatter
#                   uses.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $class    in      scalar    Name of class
#                   $template in      scalar    String template for formatter
#                   @args     in      scalar    Everything else (see code)
#
#   Returns:        Success:    new object
#                   Failure:    dies
#
###############################################################################
sub new {
    my ($class, $template, @args) = @_;

    croak 'new requires string template argument' if (! defined $template);

    my $args = @args == 1 ? $args[0] : { @args };
    my $self = bless {
        template => $template,
        bindings => undef,
        on_undef => 'warn',
    }, $class;

    $self->_compile;
    if ($args->{bindings}) {
        $self->bind($args->{bindings});
    }
    if ($args->{on_undef}) {
        croak "new: Invalid value for 'on_undef' ($args->{on_undef})"
            if (! $VALID_ON_UNDEF{$args->{on_undef}});
        $self->{on_undef} = $args->{on_undef};
    }

    return $self;
}

###############################################################################
#
#   Sub Name:       bind
#
#   Description:    Add or change object-level bindings
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#                   $bindings in      ref       New bindings
#
#   Globals:        %NOT_ACCEPTABLE_REF
#
#   Returns:        Success:    $self
#                   Failure:    dies
#
###############################################################################
sub bind { ## no critic(ProhibitBuiltinHomonyms)
    my ($self, $bindings) = @_;

    if ((@_ == 2) && (! defined $bindings)) {
        # The means of unbinding is to call $obj->bind(undef):
        undef $self->{bindings};
    } else {
        croak 'bind: New bindings must be provided as a parameter'
            if (! $bindings);

        my $type = ref $bindings;
        if (! $type) {
            croak 'New bindings must be a reference (HASH, ARRAY or object)';
        } elsif ($NOT_ACCEPTABLE_REF{$type}) {
            croak "New bindings reference type ($type) not usable";
        }

        $self->{bindings} = $bindings;
    }

    return $self;
}

###############################################################################
#
#   Sub Name:       format
#
#   Description:    Front-end to the recursive _format routine, which does the
#                   bulk of the parsing/interpolation of the object's template
#                   against the given bindings.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#                   $bindings in      ref       Optional, bindings to use in
#                                                 interpolation. Defaults to
#                                                 object-level bindings.
#
#   Returns:        Success:    string
#                   Failure:    dies
#
###############################################################################
sub format { ## no critic(ProhibitBuiltinHomonyms)
    my ($self, $bindings) = @_;

    $bindings ||= $self->bindings;
    croak 'format: Bindings are required if object has no internal bindings'
        if (! $bindings);

    my $value = join q{} =>
        map { ref() ? $self->_format($bindings, @{$_}) : $_ }
        @{$self->{_compiled}};

    return $value;
}

# Private functions that support the public API:

# Compile the template into a tree structure that can be easily traversed for
# formatting.
sub _compile {
    my $self = shift;

    my @tokens = $self->_tokenize;

    my @stack = ([]);
    my $level = 0;
    my @opens = ();

    while (my ($type, $value) = splice @tokens, 0, 2) {
        if ($type eq 'STRING') {
            push @{$stack[$level]}, $value;
        } elsif ($type eq 'OPEN') {
            push @stack, [];
            $level++;
            push @opens, $value;
        } else {
            # Must be 'CLOSE'.
            if ($level) {
                my $subtree = pop @stack;
                $level--;
                push @{$stack[$level]}, $subtree;
                pop @opens;
            } else {
                croak "Unmatched closing brace at position $value";
            }
        }
    }

    if ($level) {
        croak sprintf '%d unmatched opening brace%s, last at position %d',
            $level, $level == 1 ? q{} : 's', pop @opens;
    }

    $self->{_compiled} = $stack[0];
    return $self;
}

# Tokenize the object's template into a sequence of (type, value) pairs that
# identify the opening and closing braces, and ordinary strings.
sub _tokenize {
    my $self = shift;

    my (@list, $base, $pos, $len);
    my $str = $self->template;

    $base = 0;
    while ($str =~ /(?<!\\)(?=[{}])/g) {
        $pos = pos $str;
        if ($len = $pos - $base) {
            (my $piece = substr $str, $base, $len) =~ s/\\([{}])/$1/g;
            push @list, 'STRING', $piece;
        }
        push @list, ('{' eq substr $str, $pos, 1) ? 'OPEN' : 'CLOSE';
        push @list, $pos;
        $base = $pos + 1;
    }

    if (length($str) > $base) {
        (my $piece = substr $str, $base) =~ s/\\([{}])/$1/g;
        push @list, 'STRING', $piece;
    }

    return @list;
}

# Does the hard and recursive part of the actual formatting. Not actually that
# hard, but a little recursive.
sub _format {
    my ($self, $bindings, @elements) = @_;

    # Slight duplication of code from format() here, but it saves having to
    # keep track of depth and do a conditional on every return.
    my $expr = join q{} =>
        map { ref() ? $self->_format($bindings, @{$_}) : $_ } @elements;

    return $self->_expr_to_value($bindings, $expr);
}

# Converts an expression like "a.b.c" into a value from the bindings
sub _expr_to_value {
    my ($self, $bindings, $string) = @_;

    my ($expr, $format) = split /:/ => $string, 2;
    # For now, $format is ignored
    my @hier = split /[.]/ => $expr;
    my $node = $bindings;

    for my $key (@hier) {
        if ($key =~ /^\d+$/) {
            if (ref $node eq 'ARRAY') {
                $node = $node->[$key];
            } else {
                croak "Key-type mismatch (key $key) in $expr, node is not " .
                    'an ARRAY ref';
            }
        } else {
            if (ref $node eq 'HASH') {
                $node = $node->{$key};
            } elsif (ref $node eq 'ARRAY') {
                croak "Key-type mismatch (key $key) in $expr, node is an " .
                    'ARRAY ref when expecting HASH or object';
            } elsif (ref $node) {
                $node = $node->$key();
            } else {
                croak "Key-type mismatch (key $key) in $expr, node is not " .
                    'a HASH ref or object';
            }
        }
    }

    # Because all the key-substitution has been done before this sub is called,
    # it's probably a bad thing if $node is a ref. It's gonna get stringified
    # as a ref, which is probably not what the caller intended.
    if (ref $node) {
        carp "Format expression $expr yielded a reference value rather than " .
            'a scalar';
    }
    # If $node is undef, react accordingly based on the "on_undef" property.
    if (! defined $node) {
        # We validated this value in new(), so no need to do so here.
        my $what_to_do = $self->on_undef;
        if ($what_to_do eq 'ignore') {
            $node = q{};
        } elsif ($what_to_do eq 'warn') {
            carp "No binding for reference to '$expr'";
            $node = q{};
        } elsif ($what_to_do eq 'die') {
            croak "No binding for reference to '$expr'";
        } else {
            # Leave the token unchanged
            $node = "{$expr}";
        }
    }

    return $node;
}

# Actual operator-overload functions:

# Handle the object stringification (the "" operator)
sub _stringify {
    my $self = shift;
    my $bindings = $self->bindings;

    return $bindings ? $self->format($bindings) : $self->template;
}

# Handle the % interpolation operator
sub _interpolate {
    my ($self, $bindings, $swap) = @_;

    if ($swap) {
        my $class = ref $self;
        croak "$class object must come first in % interpolation";
    }

    return $self->format($bindings);
}

# Handle the 'cmp' operator
sub _cmp {
    my ($self, $other, $swap) = @_;

    return $swap ?
        ($other cmp $self->_stringify) : ($self->_stringify cmp $other);
}

# Handle the 'eq' operator
sub _eq {
    my ($self, $other, $swap) = @_;

    return $self->_stringify eq $other;
}

# Handle the 'ne' operator
sub _ne {
    my ($self, $other, $swap) = @_;

    return $self->_stringify ne $other;
}

# Handle the 'lt' operator
sub _lt {
    my ($self, $other, $swap) = @_;

    return $swap ?
        ($other lt $self->_stringify) : ($self->_stringify lt $other);
}

# Handle the 'le' operator
sub _le {
    my ($self, $other, $swap) = @_;

    return $swap ?
        ($other le $self->_stringify) : ($self->_stringify le $other);
}

# Handle the 'gt' operator
sub _gt {
    my ($self, $other, $swap) = @_;

    return $swap ?
        ($other gt $self->_stringify) : ($self->_stringify gt $other);
}

# Handle the 'ge' operator
sub _ge {
    my ($self, $other, $swap) = @_;

    return $swap ?
        ($other ge $self->_stringify) : ($self->_stringify ge $other);
}

# Handle the '.' operator
sub _dot {
    my ($self, $other, $swap) = @_;

    return $swap ?
        $other . $self->_stringify : $self->_stringify . $other;
}

# Handle the '.=' operator
sub _dotequal {
    my ($self, $other, $swap) = @_;

    if (! $swap) {
        my $class = ref $self;
        croak "$class object cannot be on the left of .=";
    }

    return $other . $self->_stringify;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

YASF - Yet Another String Formatter

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    use YASF;
    use LWP::Simple;
    
    my $str = YASF->new('https://google.com/?q={search}');
    for my $term qw(<search terms>) {
        $results{$term} = get($str % { search => $term });
    }

=head1 DESCRIPTION

NOTE: This is an early release, and should be considered alpha-quality. The
interface is subject to change in future versions.

B<YASF> is a string-formatting module with functionality inspired by the C<%>
string operator and C<format> method of the string class from Python.

B<YASF> is not a direct port of these features, so they are not strictly
identical in nature. Instead, B<YASF> provides a handful of methods and an
overload of some operators. This allows you to create your template string and
interpolate it either with a direct call to B<format>, or using C<%> as an
operator similar in syntax to Python.

=head2 Interpolation Syntax

The syntax for interpolating the pattern string is fairly simple:

    "some text {key} some more text"

When interpolated, the string C<{key}> will be replaced with the value of C<key>
in the bindings for the interpolation.

Because the bindings can be almost any arbitrary Perl data structure, the keys
may be multi-part, in a hierarchy denoted by dots (C<.>):

    {key1.key2.key3}

The above will first look up C<key1> in the bindings, which it will expect to
be a hash reference. The value that C<key1> yields will also be expected to be
a hash reference, and C<key2> will be looked up in that table, and so on.

Keys may also be numeric, in which case it is expected that the corresponding
binding being indexed is an array reference:

    {3}

Numeric and string keys may be interspersed, if the underlying data structure
follows the same pattern:

    {key.0.name}

When a key expression is being evaluated into a value, an exception is thrown
if the key-type is not appropriate for the node at that position in the data
structure.

Keys may also be nested:

    {key.{subkey}}

In such a case, C<subkey> is evaluated first, and the value from it is used
to construct the full key.

The value from a nested key is not evaluated recursively, as this could lead to
endless recursion. That is, if C<subkey> evaluated to C<{key2}>, it would
B<not> result in C<key2> being interpolated. Instead, a literal key of
C<{key2}> would be looked up on the hash reference that C<key> yields.

Because curly braces are used to delimit keys, if you want a curly brace (of
either orientation) in your string you will need to escape it with a
backslash character:

    $str = YASF->new('\{{key}\}');

or

    $str = YASF->new("\\{{key}\\}");

The escaped characters will be converted when the template is compiled
internally.

A key may be made up of any characters, though for readability it is
recommended that you stay with alphanumerics. The only character that cannot
be used in a key is the colon (C<:>), as this is used to delimit a key from
a formatting specification (see L</Formatting Syntax>).

=head2 Using Objects in the Bindings

If an element within the bindings data structure is an object, the key for
that node will be used as the name of a method and called on the object. The
method will be called with no parameters, and is expected to return a scalar
value (be that an ordinary value or a reference).

For example:

    require HTTP::Daemon;
    
    my $str = YASF->new("{d.product_tokens} listening at {d.url}\n");
    my $d = HTTP::Daemon->new;
    print $str % { d => $d };

However, in this case there's no reason that the object itself cannot be the
binding:

    require HTTP::Daemon;
    
    my $str = YASF->new("{product_tokens} listening at {url}\n");
    my $d = HTTP::Daemon->new;
    print $str % $d;

=head2 Formatting Syntax

Python's C<format> also supports an extensive syntax for formatting the data
that gets substituted. A format specification is given in the key, as a string
sequence separated from the key itself by a colon:

    {key1.key2:6.2f}

This is not yet implemented in B<YASF>, but will be added in a future release.
For now, if a formatting string is detected it will be ignored.

=head1 OVERLOADED OPERATORS

The B<YASF> class overrides a number of operators. Any operators not explicitly
listed here will not fall back to any Perl defaults, they will instead trigger
a run-time error.

=over 4

=item C<%>

The C<%> operator causes the interpolation of a B<YASF> template against the
bindings that are passed following the operator:

    print $str % $data;
    # or
    print $str % { ... };
    # or
    print $str % [ ... ];

If the object has been bound to a data structure already (see the B<bind>
method, below), the explicitly-provided bindings take precedence over the
object-level binding.

=item C<""> (stringification)

When a B<YASF> object is stringified, one of two things happens:

=over

=item 1.

If the object is bound to a data structure via B<bind> (or from a C<bindings>
argument in the constructor), it is interpolated against these bindings and
the resulting string is used.

=item 2.

If the object has no object-level bindings, then the uninterpolated template
string will be used.

=back

You do not need to explicitly use double-quotes to trigger this; anywhere the
object would be used as a string (printing, hash keys, etc.), this will be the
behavior.

=item String Comparison (C<cmp>, C<eq>, etc.)

The string comparison operators (C<cmp>, C<eq>, C<ne>, C<lt>, C<le>, C<gt>,
C<ge>) are all overloaded to stringify the B<YASF> object before doing the
actual comparison. As with C<"">, if no object-level bindings exist then the
stringification is just the template string itself.

=item String Concatenation (C<.> and C<.=>)

The string concatenation operators, C<.> and C<.=>, are also overloaded. The
C<.> operator always stringifies the object involved in the operation (with
the same effect as the comparison operators when no bindings exist), regardless
of which side of the operator it appears on.

The C<.=> operator, however, can only accept a B<YASF> object on the right-hand
side. This is because B<YASF> template strings are (currently) read-only. If
you try to use an object on the left-hand side of C<.=>, an exception is
thrown.

=back

Other operators may be overloaded in the future, as deemed useful or
necessary.

=head1 SUBROUTINES/METHODS

The following methods and subroutines are provided by this module:

=over 4

=item B<new>

This is the object constructor. It takes one required argument and optional
named arguments following that. The required argument is the string template
that will be interpolated. The named arguments may be passed as a hash
reference or as key/value pairs. The following parameters are recognized:

=over

=item B<bindings>

Specifies the bindings for the object. The value must be an array reference, a
hash reference, or an object referent.

=item B<on_undef>

Specifies the behavior for the interpolation when the key being interpolated
has no value in the bindings (i.e., the value is C<undef>). The possible values
are:

=over

=item C<warn>

A warning is issued (using B<carp>), similar to what Perl would do for
interpolating an undefined value. However, the message specifies the token that
had no value.

=item C<die>

An error is issued (using B<croak>), with the same message as C<warn> generates.

=item C<ignore>

The missing token is ignored, and a null string is inserted in its place.

=item C<token>

The missing token is left in place, unchanged.

=back

Note that if the token is the result of a "compound token", the token you see
in the messages or left intact within the string may differ from what is in the
template.

The default value is C<warn>.

=back

The return value is a new object of the class. Any errors will be signaled via
B<croak>.

=item B<bind>

This method binds the object to a data structure reference. When an object has
a bound data structure, it can be formatted or interpolated in a string without
needed explicit bindings to be provided. This can be useful when binding to a
hash reference whose contents will continually change, or an object whose
internal state is continuously changing.

The method takes one required argument, the new bindings. This must be a
reference to a hash, to an array, or to an object. If the argument does not
meet these criteria (or is not given), an exception is thrown via B<croak>.

If an object has a bound data structure, but is interpolated with C<%> or
B<format> with an explicit set of bindings, the explicit bindings will
supercede the internal bindings (but without replacing it permanently).

You can unbind data from the object by calling B<bind> with C<undef> as the
argument.

=item B<format>

This method formats the template within the object, using either bindings
provided as an argument or using the object-level bindings that are already
set.

=item B<bindings>

A static accessor that returns the current object-level bindings data structure,
or B<undef> if there are no object-level bindings. Cannot be used to set the
bindings; see B<bind>, above.

=item B<template>

A static accessor that returns the template string that this object is
encapsulating. Cannot be used to change the template.

(At present, there is no way to change the template of an object. You can only
create a new object.)

=item B<on_undef>

A static accessor that returns the value of the C<on_undef> property of the
object. Like the C<template> property, this cannot be changed on an object once
the object is created.

=item B<YASF>

This is a convenience function for quickly creating an unbound B<YASF> object.
It requires the template string as the only parameter and returns a new object.
This can be useful for one-off usage, etc., and is a few characters shorter
than calling B<new> directly:

    require HTTP::Daemon;
    
    my $d = HTTP::Daemon->new;
    print YASF "{product_tokens} listening at {url}\n" % $d;

The only real difference between this and B<new>, is that you cannot pass any
additional arguments to B<YASF>.

The B<YASF> function is not exported by default; you must explicitly import it:

    use YASF 'YASF';

=back

=head1 DIAGNOSTICS

Presently, all errors are signaled via the B<croak> function. This may change
as the module evolves.

=head1 BUGS

As this is alpha software, the likelihood of bugs is pretty close to 100%.
Please report any issues you find to either the CPAN RT instance or to the
GitHub issues page:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=YASF>

=item * GitHub Issues page

L<https://github.com/rjray/yasf/issues>

=back

=head1 SUPPORT

=over 4

=item * Source code on GitHub

L<https://github.com/rjray/yasf>

=item * MetaCPAN

L<https://metacpan.org/release/YASF>

=back

=head1 LICENSE AND COPYRIGHT

This file and the code within are copyright © 2016 by Randy J. Ray.

Copying and distribution are permitted under the terms of the Artistic
License 1.0 or the GNU GPL 1. See the file F<LICENSE> in the distribution of
this module.

=head1 AUTHOR

Randy J. Ray <rjray@blackperl.com>
