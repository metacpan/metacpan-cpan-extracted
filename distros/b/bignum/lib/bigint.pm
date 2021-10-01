package bigint;

use 5.010;
use strict;
use warnings;

use Carp qw< carp croak >;

our $VERSION = '0.61';

use Exporter;
our @ISA            = qw( Exporter );
our @EXPORT_OK      = qw( PI e bpi bexp hex oct );
our @EXPORT         = qw( inf NaN );

use overload;
use Math::BigInt;

##############################################################################

sub accuracy {
    my $self = shift;
    Math::BigInt -> accuracy(@_);
}

sub precision {
    my $self = shift;
    Math::BigInt -> precision(@_);
}

sub round_mode {
    my $self = shift;
    Math::BigInt -> round_mode(@_);
}

sub div_scale {
    my $self = shift;
    Math::BigInt -> div_scale(@_);
}

sub in_effect {
    my $level = shift || 0;
    my $hinthash = (caller($level))[10];
    $hinthash->{bigint};
}

sub _float_constant {
    my $str = shift;

    # We can't pass input directly to new() because of the way it handles the
    # combination of non-integers with no upgrading. Such cases are by
    # Math::BigInt returned as NaN, but we truncate to an integer.

    # See if we can convert the input string to a string using a normalized form
    # consisting of the significand as a signed integer, the character "e", and
    # the exponent as a signed integer, e.g., "+0e+0", "+314e-2", and "-1e+3".

    my $nstr;

    if (
        # See if it is an octal number. An octal number like '0377' is also
        # accepted by the functions parsing decimal and hexadecimal numbers, so
        # handle octal numbers before decimal and hexadecimal numbers.

        $str =~ /^0(?:[Oo]|_*[0-7])/ and
        $nstr = Math::BigInt -> oct_str_to_dec_flt_str($str)

          or

        # See if it is decimal number.

        $nstr = Math::BigInt -> dec_str_to_dec_flt_str($str)

          or

        # See if it is a hexadecimal number. Every hexadecimal number has a
        # prefix, but the functions parsing numbers don't require it, so check
        # to see if it actually is a hexadecimal number.

        $str =~ /^0[Xx]/ and
        $nstr = Math::BigInt -> hex_str_to_dec_flt_str($str)

          or

        # See if it is a binary numbers. Every binary number has a prefix, but
        # the functions parsing numbers don't require it, so check to see if it
        # actually is a binary number.

        $str =~ /^0[Bb]/ and
        $nstr = Math::BigInt -> bin_str_to_dec_flt_str($str))
    {
        my $pos      = index($nstr, 'e');
        my $expo_sgn = substr($nstr, $pos + 1, 1);
        my $sign     = substr($nstr, 0, 1);
        my $mant     = substr($nstr, 1, $pos - 1);
        my $mant_len = CORE::length($mant);
        my $expo     = substr($nstr, $pos + 2);

        if ($expo_sgn eq '-') {
            my $upgrade = Math::BigInt -> upgrade();
            return $upgrade -> new($nstr) if defined $upgrade;

            if ($mant_len <= $expo) {
                return Math::BigInt -> bzero();                 # underflow
            } else {
                $mant = substr $mant, 0, $mant_len - $expo;     # truncate
                return Math::BigInt -> new($sign . $mant);
            }
        } else {
            $mant .= "0" x $expo;                               # pad with zeros
            return Math::BigInt -> new($sign . $mant);
        }
    }

    # If we get here, there is a bug in the code above this point.

    warn "Internal error: unable to handle literal constant '$str'.",
      " This is a bug, so please report this to the module author.";
    return Math::BigInt -> bnan();
}

#############################################################################
# the following two routines are for "use bigint qw/hex oct/;":

use constant LEXICAL => $] > 5.009004;

# Internal function with the same semantics as CORE::hex(). This function is
# not used directly, but rather by other front-end functions.

sub _hex_core {
    my $str = shift;

    # Strip off, clean, and parse as much as we can from the beginning.

    my $x;
    if ($str =~ s/ ^ ( 0? [xX] )? ( [0-9a-fA-F]* ( _ [0-9a-fA-F]+ )* ) //x) {
        my $chrs = $2;
        $chrs =~ tr/_//d;
        $chrs = '0' unless CORE::length $chrs;
        $x = Math::BigInt -> from_hex($chrs);
    } else {
        $x = Math::BigInt -> bzero();
    }

    # Warn about trailing garbage.

    if (CORE::length($str)) {
        require Carp;
        Carp::carp(sprintf("Illegal hexadecimal digit '%s' ignored",
                           substr($str, 0, 1)));
    }

    return $x;
}

# Internal function with the same semantics as CORE::oct(). This function is
# not used directly, but rather by other front-end functions.

sub _oct_core {
    my $str = shift;

    $str =~ s/^\s*//;

    # Hexadecimal input.

    return _hex_core($str) if $str =~ /^0?[xX]/;

    my $x;

    # Binary input.

    if ($str =~ /^0?[bB]/) {

        # Strip off, clean, and parse as much as we can from the beginning.

        if ($str =~ s/ ^ ( 0? [bB] )? ( [01]* ( _ [01]+ )* ) //x) {
            my $chrs = $2;
            $chrs =~ tr/_//d;
            $chrs = '0' unless CORE::length $chrs;
            $x = Math::BigInt -> from_bin($chrs);
        }

        # Warn about trailing garbage.

        if (CORE::length($str)) {
            require Carp;
            Carp::carp(sprintf("Illegal binary digit '%s' ignored",
                               substr($str, 0, 1)));
        }

        return $x;
    }

    # Octal input. Strip off, clean, and parse as much as we can from the
    # beginning.

    if ($str =~ s/ ^ ( 0? [oO] )? ( [0-7]* ( _ [0-7]+ )* ) //x) {
        my $chrs = $2;
        $chrs =~ tr/_//d;
        $chrs = '0' unless CORE::length $chrs;
        $x = Math::BigInt -> from_oct($chrs);
    }

    # Warn about trailing garbage. CORE::oct() only warns about 8 and 9, but it
    # is more helpful to warn about all invalid digits.

    if (CORE::length($str)) {
        require Carp;
        Carp::carp(sprintf("Illegal octal digit '%s' ignored",
                           substr($str, 0, 1)));
    }

    return $x;
}

{
    my $proto = LEXICAL ? '_' : ';$';
    eval '
sub hex(' . $proto . ') {' . <<'.';
    my $str = @_ ? $_[0] : $_;
    _hex_core($str);
}
.

    eval '
sub oct(' . $proto . ') {' . <<'.';
    my $str = @_ ? $_[0] : $_;
    _oct_core($str);
}
.
}

#############################################################################
# the following two routines are for Perl 5.9.4 or later and are lexical

my ($prev_oct, $prev_hex, $overridden);

if (LEXICAL) { eval <<'.' }
sub _hex(_) {
    my $hh = (caller 0)[10];
    return $$hh{bigint} ? bigint::_hex_core($_[0])
         : $$hh{bignum} ? bignum::_hex_core($_[0])
         : $$hh{bigrat} ? bigrat::_hex_core($_[0])
         : $prev_hex    ? &$prev_hex($_[0])
         : CORE::hex($_[0]);
}

sub _oct(_) {
    my $hh = (caller 0)[10];
    return $$hh{bigint} ? bigint::_oct_core($_[0])
         : $$hh{bignum} ? bignum::_oct_core($_[0])
         : $$hh{bigrat} ? bigrat::_oct_core($_[0])
         : $prev_oct    ? &$prev_oct($_[0])
         : CORE::oct($_[0]);
}
.

sub _override {
    return if $overridden;
    $prev_oct = *CORE::GLOBAL::oct{CODE};
    $prev_hex = *CORE::GLOBAL::hex{CODE};
    no warnings 'redefine';
    *CORE::GLOBAL::oct = \&_oct;
    *CORE::GLOBAL::hex = \&_hex;
    $overridden = 1;
}

sub unimport {
    $^H{bigint} = undef;        # no longer in effect
    overload::remove_constant('binary', '', 'float', '', 'integer');
}

sub import {
    my $self = shift;

    $^H{bigint} = 1;                            # we are in effect
    $^H{bignum} = undef;
    $^H{bigrat} = undef;

    # for newer Perls always override hex() and oct() with a lexical version:
    if (LEXICAL) {
        _override();
    }

    # some defaults
    my $lib      = '';
    my $lib_kind = 'try';

    my @import = ();
    my @a = ();
    my ($ver, $trace);                          # version? trace?

    while (@_) {
        my $param = shift;
        if ($param eq 'upgrade') {
            # this causes upgrading
            push @import, 'upgrade', shift;
        } elsif ($param eq 'downgrade') {
            # this causes downgrading
            push @import, 'downgrade', shift;
        } elsif ($param =~ /^(l|lib|try|only)$/) {
            # this causes a different low lib to take care...
            $lib_kind = $param;
            $lib_kind = 'lib' if $lib_kind eq 'l';
            $lib = shift() || '';
        } elsif ($param =~ /^(a|accuracy)$/) {
            push @import, 'accuracy', shift;
        } elsif ($param =~ /^(p|precision)$/) {
            push @import, 'precision', shift;
        } elsif ($param =~ /^(v|version)$/) {
            $ver = 1;
        } elsif ($param =~ /^(t|trace)$/) {
            $trace = 1;
        } elsif ($param =~ /^(PI|e|bexp|bpi|hex|oct)\z/) {
            push @a, $param;
        } else {
            croak("Unknown option '$param'");
        }
    }

    my $class = "Math::BigInt";
    if ($trace) {
        require Math::BigInt::Trace;
        $class = "Math::BigInt::Trace";
    }
    push @import, $lib_kind => $lib if $lib ne '';
    $class -> import(@import);

    if ($ver) {
        print "bigint\t\t\t v$VERSION\n";
        my $config = $class -> config();
        print " lib => $config->{lib} v$config->{lib_version}\n";
        print $class, "\t\t v",! $class -> VERSION, "\n";
        exit;
    }

    overload::constant

        # This takes care each number written as decimal integer and within the
        # range of what perl can represent as an integer, e.g., "314", but not
        # "3141592653589793238462643383279502884197169399375105820974944592307".

        integer => sub {
            #printf "Value '%s' handled by the 'integer' sub.\n", $_[0];
            my $str = shift;
            return Math::BigInt -> new($str);
        },

        # This takes care of each number written with a decimal point and/or
        # using floating point notation, e.g., "3.", "3.0", "3.14e+2" (decimal),
        # "0b1.101p+2" (binary), "03.14p+2" and "0o3.14p+2" (octal), and
        # "0x3.14p+2" (hexadecimal).

        float => sub {
            #printf "# Value '%s' handled by the 'float' sub.\n", $_[0];
            _float_constant(shift);
        },

        # Take care of each number written as an integer (no decimal point or
        # exponent) using binary, octal, or hexadecimal notation, e.g., "0b101"
        # (binary), "0314" and "0o314" (octal), and "0x314" (hexadecimal).

        binary => sub {
            #printf "# Value '%s' handled by the 'binary' sub.\n", $_[0];
            my $str = shift;
            return Math::BigInt -> new($str) if $str =~ /^0[XxBb]/;
            Math::BigInt -> from_oct($str);
        };

    # if another big* was already loaded:
    my ($package) = caller();

    no strict 'refs';
    if (!defined *{"${package}::inf"}) {
        $self->export_to_level(1, $self, @a);   # export inf and NaN, e and PI
    }
}

sub inf () { Math::BigInt -> binf(); }
sub NaN () { Math::BigInt -> bnan(); }

sub PI  () { Math::BigInt -> new(3); }
sub e   () { Math::BigInt -> new(2); }

sub bpi ($) { Math::BigInt -> new(3); }
sub bexp ($$) {
    my $x = Math::BigInt -> new($_[0]);
    $x -> bexp($_[1]);
}

1;

__END__

=pod

=head1 NAME

bigint - transparent big integer support for Perl

=head1 SYNOPSIS

    use bigint;

    $x = 2 + 4.5,"\n";                    # Math::BigInt 6
    print 2 ** 512,"\n";                  # really is what you think it is
    print inf + 42,"\n";                  # inf
    print NaN * 7,"\n";                   # NaN
    print hex("0x1234567890123490"),"\n"; # Perl v5.10.0 or later

    {
        no bigint;
        print 2 ** 256,"\n";              # a normal Perl scalar now
    }

    # for older Perls, import into current package:
    use bigint qw/hex oct/;
    print hex("0x1234567890123490"),"\n";
    print oct("01234567890123490"),"\n";

=head1 DESCRIPTION

All operators (including basic math operations) except the range operator C<..>
are overloaded. All literal numeric constants are converted to Math::BigInt
objects.

Constants that represent an integer value are truncated to integer. All parts
and results of expressions are also truncated.

Unlike L<integer>, this pragma creates integer constants that are only
limited in their size by the available memory and CPU time.

=head2 use integer vs. use bigint

There are some difference between C<use integer> and C<use bigint>.

Whereas C<use integer> is limited to what can be handled as a Perl scalar, C<use
bigint> can handle arbitrarily large integers.

Also, C<use integer> does affect assignments to variables and the return value
of some functions. C<use bigint> truncates these results to integer:

    # perl -Minteger -wle 'print 3.2'
    3.2
    # perl -Minteger -wle 'print 3.2 + 0'
    3
    # perl -Mbigint -wle 'print 3.2'
    3
    # perl -Mbigint -wle 'print 3.2 + 0'
    3

    # perl -Mbigint -wle 'print exp(1) + 0'
    2
    # perl -Mbigint -wle 'print exp(1)'
    2
    # perl -Minteger -wle 'print exp(1)'
    2.71828182845905
    # perl -Minteger -wle 'print exp(1) + 0'
    2

In practice this seldom makes a difference as B<parts and results> of
expressions will be truncated anyway, but this can, for instance, affect the
return value of subroutines:

    sub three_integer { use integer; return 3.2; }
    sub three_bigint { use bigint; return 3.2; }

    print three_integer(), " ", three_bigint(),"\n";    # prints "3.2 3"

=head2 Options

bigint recognizes some options that can be passed while loading it via use.
The options can (currently) be either a single letter form, or the long form.
The following options exist:

=over 2

=item a or accuracy

This sets the accuracy for all math operations. The argument must be greater
than or equal to zero. See Math::BigInt's bround() function for details.

    perl -Mbigint=a,2 -le 'print 12345+1'

Note that setting precision and accuracy at the same time is not possible.

=item p or precision

This sets the precision for all math operations. The argument can be any
integer. Negative values mean a fixed number of digits after the dot, and
are <B>ignored</B> since all operations happen in integer space.
A positive value rounds to this digit left from the dot. 0 or 1 mean round to
integer and are ignore like negative values.

See Math::BigInt's bfround() function for details.

    perl -Mbigint=p,5 -le 'print 123456789+123'

Note that setting precision and accuracy at the same time is not possible.

=item t or trace

This enables a trace mode and is primarily for debugging bigint or
Math::BigInt.

=item hex

Override the built-in hex() method with a version that can handle big
integers. This overrides it by exporting it to the current package. Under
Perl v5.10.0 and higher, this is not so necessary, as hex() is lexically
overridden in the current scope whenever the bigint pragma is active.

=item oct

Override the built-in oct() method with a version that can handle big
integers. This overrides it by exporting it to the current package. Under
Perl v5.10.0 and higher, this is not so necessary, as oct() is lexically
overridden in the current scope whenever the bigint pragma is active.

=item l, lib, try or only

Load a different math lib, see L<Math Library>.

    perl -Mbigint=lib,GMP -e 'print 2 ** 512'
    perl -Mbigint=try,GMP -e 'print 2 ** 512'
    perl -Mbigint=only,GMP -e 'print 2 ** 512'

Currently there is no way to specify more than one library on the command
line. This means the following does not work:

    perl -Mbigint=l,GMP,Pari -e 'print 2 ** 512'

This will be hopefully fixed soon ;)

=item v or version

This prints out the name and version of all modules used and then exits.

    perl -Mbigint=v

=back

=head2 Math Library

Math with the numbers is done (by default) by a module called
Math::BigInt::Calc. This is equivalent to saying:

    use bigint lib => 'Calc';

You can change this by using:

    use bigint lib => 'GMP';

The following would first try to find Math::BigInt::Foo, then
Math::BigInt::Bar, and when this also fails, revert to Math::BigInt::Calc:

    use bigint lib => 'Foo,Math::BigInt::Bar';

Using C<lib> warns if none of the specified libraries can be found and
L<Math::BigInt> did fall back to one of the default libraries.
To suppress this warning, use C<try> instead:

    use bigint try => 'GMP';

If you want the code to die instead of falling back, use C<only> instead:

    use bigint only => 'GMP';

Please see respective module documentation for further details.

=head2 Internal Format

The numbers are stored as objects, and their internals might change at anytime,
especially between math operations.

You should not depend on the internal format, all accesses must go through
accessor methods. E.g. looking at $x->{sign} is not a good idea since there
is no guaranty that the object in question has such a hash key, nor is a hash
underneath at all.

=head2 Sign

The sign is either '+', '-', 'NaN', '+inf' or '-inf'.
You can access it with the sign() method.

A sign of 'NaN' is used to represent the result when input arguments are not
numbers or as a result of 0/0. '+inf' and '-inf' represent plus respectively
minus infinity. You will get '+inf' when dividing a positive number by 0, and
'-inf' when dividing any negative number by 0.

=head2 Method calls

Since all numbers are now objects, you can use all functions that are part of
the Math::BigInt API. You can only use the bxxx() notation, and not the fxxx()
notation, though.

But a warning is in order. When using the following to make a copy of a number,
only a shallow copy will be made.

    $x = 9; $y = $x;
    $x = $y = 7;

Using the copy or the original with overloaded math is okay, e.g. the
following work:

    $x = 9; $y = $x;
    print $x + 1, " ", $y,"\n";     # prints 10 9

but calling any method that modifies the number directly will result in
B<both> the original and the copy being destroyed:

    $x = 9; $y = $x;
    print $x->badd(1), " ", $y,"\n";        # prints 10 10

    $x = 9; $y = $x;
    print $x->binc(1), " ", $y,"\n";        # prints 10 10

    $x = 9; $y = $x;
    print $x->bmul(2), " ", $y,"\n";        # prints 18 18

Using methods that do not modify, but test that the contents works:

    $x = 9; $y = $x;
    $z = 9 if $x->is_zero();                # works fine

See the documentation about the copy constructor and C<=> in overload, as
well as the documentation in Math::BigInt for further details.

=head2 Methods

=over 2

=item inf()

A shortcut to return Math::BigInt->binf(). Useful because Perl does not always
handle bareword C<inf> properly.

=item NaN()

A shortcut to return Math::BigInt->bnan(). Useful because Perl does not always
handle bareword C<NaN> properly.

=item e

    # perl -Mbigint=e -wle 'print e'

Returns Euler's number C<e>, aka exp(1). Note that under bigint, this is
truncated to an integer, and hence simple '2'.

=item PI

    # perl -Mbigint=PI -wle 'print PI'

Returns PI. Note that under bigint, this is truncated to an integer, and hence
simple '3'.

=item bexp()

    bexp($power,$accuracy);

Returns Euler's number C<e> raised to the appropriate power, to
the wanted accuracy.

Note that under bigint, the result is truncated to an integer.

Example:

    # perl -Mbigint=bexp -wle 'print bexp(1,80)'

=item bpi()

    bpi($accuracy);

Returns PI to the wanted accuracy. Note that under bigint, this is truncated
to an integer, and hence simple '3'.

Example:

    # perl -Mbigint=bpi -wle 'print bpi(80)'

=item upgrade()

Return the class that numbers are upgraded to, is in fact returning
C<$Math::BigInt::upgrade>.

=item in_effect()

    use bigint;

    print "in effect\n" if bigint::in_effect;       # true
    {
        no bigint;
        print "in effect\n" if bigint::in_effect;     # false
    }

Returns true or false if C<bigint> is in effect in the current scope.

This method only works on Perl v5.9.4 or later.

=back

=head1 CAVEATS

=over 2

=item Hexadecimal, octal, and binary floating point literals

Perl (and this module) accepts hexadecimal, octal, and binary floating point
literals, but use them with care with Perl versions before v5.32.0, because some
versions of Perl silently give the wrong result.

=item Operator vs literal overloading

C<bigint> works by overloading handling of integer and floating point literals,
converting them to L<Math::BigInt> objects.

This means that arithmetic involving only string values or string literals are
performed using Perl's built-in operators.

For example:

    use bigint;
    my $x = "900000000000000009";
    my $y = "900000000000000007";
    print $x - $y;

will output C<0> on default 32-bit builds, since C<bigint> never sees
the string literals.  To ensure the expression is all treated as
C<Math::BigInt> objects, use a literal number in the expression:

    print +(0+$x) - $y;

=item ranges

Perl does not allow overloading of ranges, so you can neither safely use
ranges with bigint endpoints, nor is the iterator variable a bigint.

    use 5.010;
    for my $i (12..13) {
      for my $j (20..21) {
        say $i ** $j;  # produces a floating-point number,
                       # not a big integer
      }
    }

=item in_effect()

This method only works on Perl v5.9.4 or later.

=item hex()/oct()

C<bigint> overrides these routines with versions that can also handle
big integer values. Under Perl prior to version v5.9.4, however, this
will not happen unless you specifically ask for it with the two
import tags "hex" and "oct" - and then it will be global and cannot be
disabled inside a scope with "no bigint":

    use bigint qw/hex oct/;

    print hex("0x1234567890123456");
    {
        no bigint;
        print hex("0x1234567890123456");
    }

The second call to hex() will warn about a non-portable constant.

Compare this to:

    use bigint;

    # will warn only under Perl older than v5.9.4
    print hex("0x1234567890123456");

=back

=head1 EXAMPLES

Some cool command line examples to impress the Python crowd ;) You might want
to compare them to the results under -Mbignum or -Mbigrat:

    perl -Mbigint -le 'print sqrt(33)'
    perl -Mbigint -le 'print 2*255'
    perl -Mbigint -le 'print 4.5+2*255'
    perl -Mbigint -le 'print 3/7 + 5/7 + 8/3'
    perl -Mbigint -le 'print 123->is_odd()'
    perl -Mbigint -le 'print log(2)'
    perl -Mbigint -le 'print 2 ** 0.5'
    perl -Mbigint=a,65 -le 'print 2 ** 0.2'
    perl -Mbigint=a,65,l,GMP -le 'print 7 ** 7777'

=head1 BUGS

For information about bugs and how to report them, see the BUGS section in the
documentation available with the perldoc command.

    perldoc bignum

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc bigint

For more information, see the SUPPORT section in the documentation available
with the perldoc command.

    perldoc bignum

=head1 LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<bignum> and L<bigrat>.

L<Math::BigInt>, L<Math::BigFloat>, L<Math::BigRat> and L<Math::Big> as well as
L<Math::BigInt::FastCalc>, L<Math::BigInt::Pari> and L<Math::BigInt::GMP>.

=head1 AUTHORS

=over 4

=item *

(C) by Tels L<http://bloodgate.com/> in early 2002 - 2007.

=item *

Maintained by Peter John Acklam E<lt>pjacklam@gmail.comE<gt>, 2014-.

=back

=cut
