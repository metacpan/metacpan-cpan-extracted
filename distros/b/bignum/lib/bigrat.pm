package bigrat;

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
use Math::BigRat;

##############################################################################

sub accuracy {
    my $self = shift;
    Math::BigRat -> accuracy(@_);
}

sub precision {
    my $self = shift;
    Math::BigRat -> precision(@_);
}

sub round_mode {
    my $self = shift;
    Math::BigRat -> round_mode(@_);
}

sub div_scale {
    my $self = shift;
    Math::BigRat -> div_scale(@_);
}

sub in_effect {
    my $level = shift || 0;
    my $hinthash = (caller($level))[10];
    $hinthash->{bigrat};
}

sub _float_constant {
    my $str = shift;

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
        return Math::BigRat -> new($nstr);
    }

    # If we get here, there is a bug in the code above this point.

    warn "Internal error: unable to handle literal constant '$str'.",
      " This is a bug, so please report this to the module author.";
    return Math::BigRat -> bnan();
}

#############################################################################
# the following two routines are for "use bigrat qw/hex oct/;":

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
        $x = Math::BigRat -> from_hex($chrs);
    } else {
        $x = Math::BigRat -> bzero();
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
            $x = Math::BigRat -> from_bin($chrs);
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
        $x = Math::BigRat -> from_oct($chrs);
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
    return $$hh{bigrat} ? bigrat::_hex_core($_[0])
         : $$hh{bignum} ? bignum::_hex_core($_[0])
         : $$hh{bigint} ? bigint::_hex_core($_[0])
         : $prev_hex    ? &$prev_hex($_[0])
         : CORE::hex($_[0]);
}

sub _oct(_) {
    my $hh = (caller 0)[10];
    return $$hh{bigrat} ? bigrat::_oct_core($_[0])
         : $$hh{bignum} ? bignum::_oct_core($_[0])
         : $$hh{bigint} ? bigint::_oct_core($_[0])
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
    $^H{bigrat} = undef;        # no longer in effect
    overload::remove_constant('binary', '', 'float', '', 'integer');
}

sub import {
    my $self = shift;

    $^H{bigrat} = 1;                            # we are in effect
    $^H{bigint} = undef;
    $^H{bignum} = undef;

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

    my $class = "Math::BigRat";
    if ($trace) {
        require Math::BigRat::Trace;
        $class = "Math::BigRat::Trace";
    }
    push @import, $lib_kind => $lib if $lib ne '';
    $class -> import(@import);

    if ($ver) {
        print "bigrat\t\t\t v$VERSION\n";
        my $config = $class -> config();
        print " lib => $config->{lib} v$config->{lib_version}\n";
        print $class, "\t\t v", $class -> VERSION, "\n";
        exit;
    }

    overload::constant

        # This takes care each number written as decimal integer and within the
        # range of what perl can represent as an integer, e.g., "314", but not
        # "3141592653589793238462643383279502884197169399375105820974944592307".

        integer => sub {
            #printf "Value '%s' handled by the 'integer' sub.\n", $_[0];
            my $str = shift;
            return Math::BigRat -> new($str);
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
            return Math::BigRat -> new($str) if $str =~ /^0[XxBb]/;
            Math::BigRat -> from_oct($str);
        };

    # if another big* was already loaded:
    my ($package) = caller();

    no strict 'refs';
    if (!defined *{"${package}::inf"}) {
        $self->export_to_level(1, $self, @a);   # export inf and NaN
    }
}

sub inf () { Math::BigRat -> binf(); }
sub NaN () { Math::BigRat -> bnan(); }

# This should depend on the current accuracy/precision. Fixme!
sub PI  () { Math::BigRat -> new('3.141592653589793238462643383279502884197'); }
sub e   () { Math::BigRat -> new('2.718281828459045235360287471352662497757'); }

sub bpi ($) {           # should return a Math::BigRat. Fixme!
    local $Math::BigFloat::upgrade;
    Math::BigFloat -> bpi(@_);
}

sub bexp ($$) {         # should return a Math::BigRat. Fixme!
    local $Math::BigFloat::upgrade;
    my $x = Math::BigFloat -> new($_[0]);
    $x -> bexp($_[1]);
}

1;

__END__

=pod

=head1 NAME

bigrat - transparent big rational number support for Perl

=head1 SYNOPSIS

    use bigrat;

    print 2 + 4.5,"\n";             # Math::BigRat 13/2
    print 1/3 + 1/4,"\n";           # produces 7/12

    {
        no bigrat;
        print 1/3,"\n";             # 0.33333...
    }

    # for older Perls, import into current package:
    use bigrat qw/hex oct/;
    print hex("0x1234567890123490"),"\n";
    print oct("01234567890123490"),"\n";

=head1 DESCRIPTION

All operators (including basic math operations) except the range operator C<..>
are overloaded. All literal numeric constants are converted to Math::BigRat
objects.

=head2 Math Library

Math with the numbers is done (by default) by a module called
Math::BigInt::Calc. This is equivalent to saying:

    use bigrat lib => 'Calc';

You can change this by using:

    use bigrat lib => 'GMP';

The following would first try to find Math::BigInt::Foo, then Math::BigInt::Bar,
and when this also fails, revert to Math::BigInt::Calc:

    use bigrat lib => 'Foo,Math::BigInt::Bar';

Using C<lib> warns if none of the specified libraries can be found and
L<Math::BigInt> did fall back to one of the default libraries. To suppress this
warning, use C<try> instead:

    use bigrat try => 'GMP';

If you want the code to die instead of falling back, use C<only> instead:

    use bigrat only => 'GMP';

Please see respective module documentation for further details.

=head2 Sign

The sign is either '+', '-', 'NaN', '+inf' or '-inf'.

A sign of 'NaN' is used to represent the result when input arguments are not
numbers or as a result of 0/0. '+inf' and '-inf' represent plus respectively
minus infinity. You will get '+inf' when dividing a positive number by 0, and
'-inf' when dividing any negative number by 0.

=head2 Methods

Since all numbers are not objects, you can use all functions that are part of
the Math::BigInt or Math::BigFloat API. It is wise to use only the bxxx()
notation, and not the fxxx() notation, though. This makes you independent on the
fact that the underlying object might morph into a different class than
Math::BigFloat.

=over 2

=item inf()

A shortcut to return Math::BigRat->binf(). Useful because Perl does not always
handle bareword C<inf> properly.

=item NaN()

A shortcut to return Math::BigRat->bnan(). Useful because Perl does not always
handle bareword C<NaN> properly.

=item e

    # perl -Mbigrat=e -wle 'print e'

Returns Euler's number C<e>, aka exp(1).

=item PI

    # perl -Mbigrat=PI -wle 'print PI'

Returns PI.

=item bexp()

    bexp($power,$accuracy);

Returns Euler's number C<e> raised to the appropriate power, to
the wanted accuracy.

Example:

    # perl -Mbigrat=bexp -wle 'print bexp(1,80)'

=item bpi()

    bpi($accuracy);

Returns PI to the wanted accuracy.

Example:

    # perl -Mbigrat=bpi -wle 'print bpi(80)'

=item upgrade()

Return the class that numbers are upgraded to, if any.

=item in_effect()

    use bigrat;

    print "in effect\n" if bigrat::in_effect;     # true
    {
        no bigrat;
        print "in effect\n" if bigrat::in_effect; # false
    }

Returns true or false if C<bigrat> is in effect in the current scope.

This method only works on Perl v5.9.4 or later.

=back

=head2 MATH LIBRARY

Math with the numbers is done (by default) by a module called

=head2 Caveat

But a warning is in order. When using the following to make a copy of a number,
only a shallow copy will be made.

    $x = 9; $y = $x;
    $x = $y = 7;

If you want to make a real copy, use the following:

    $y = $x->copy();

Using the copy or the original with overloaded math is okay, e.g. the following
work:

    $x = 9; $y = $x;
    print $x + 1, " ", $y,"\n";     # prints 10 9

but calling any method that modifies the number directly will result in B<both>
the original and the copy being destroyed:

    $x = 9; $y = $x;
    print $x->badd(1), " ", $y,"\n";        # prints 10 10

    $x = 9; $y = $x;
    print $x->binc(1), " ", $y,"\n";        # prints 10 10

    $x = 9; $y = $x;
    print $x->bmul(2), " ", $y,"\n";        # prints 18 18

Using methods that do not modify, but testthe contents works:

    $x = 9; $y = $x;
    $z = 9 if $x->is_zero();                # works fine

See the documentation about the copy constructor and C<=> in overload, as well
as the documentation in Math::BigInt for further details.

=head2 Options

bigrat recognizes some options that can be passed while loading it via use. The
options can (currently) be either a single letter form, or the long form. The
following options exist:

=over 2

=item a or accuracy

This sets the accuracy for all math operations. The argument must be greater
than or equal to zero. See Math::BigInt's bround() function for details.

    perl -Mbigrat=a,50 -le 'print sqrt(20)'

Note that setting precision and accuracy at the same time is not possible.

=item p or precision

This sets the precision for all math operations. The argument can be any
integer. Negative values mean a fixed number of digits after the dot, while a
positive value rounds to this digit left from the dot. 0 or 1 mean round to
integer. See Math::BigInt's bfround() function for details.

    perl -Mbigrat=p,-50 -le 'print sqrt(20)'

Note that setting precision and accuracy at the same time is not possible.

=item t or trace

This enables a trace mode and is primarily for debugging bigrat or
Math::BigInt/Math::BigFloat.

=item l or lib

Load a different math lib, see L<MATH LIBRARY>.

    perl -Mbigrat=l,GMP -e 'print 2 ** 512'

Currently there is no way to specify more than one library on the command
line. This means the following does not work:

    perl -Mbigrat=l,GMP,Pari -e 'print 2 ** 512'

This will be hopefully fixed soon ;)

=item hex

Override the built-in hex() method with a version that can handle big numbers.
This overrides it by exporting it to the current package. Under Perl v5.10.0 and
higher, this is not so necessary, as hex() is lexically overridden in the
current scope whenever the bigrat pragma is active.

=item oct

Override the built-in oct() method with a version that can handle big numbers.
This overrides it by exporting it to the current package. Under Perl v5.10.0 and
higher, this is not so necessary, as oct() is lexically overridden in the
current scope whenever the bigrat pragma is active.

=item v or version

This prints out the name and version of all modules used and then exits.

    perl -Mbigrat=v

=back

=head1 CAVEATS

=over 2

=item Hexadecimal, octal, and binary floating point literals

Perl (and this module) accepts hexadecimal, octal, and binary floating point
literals, but use them with care with Perl versions before v5.32.0, because some
versions of Perl silently give the wrong result.

=item Operator vs literal overloading

C<bigrat> works by overloading handling of integer and floating point literals,
converting them to L<Math::BigRat> objects.

This means that arithmetic involving only string values or string literals are
performed using Perl's built-in operators.

For example:

    use bigrat;
    my $x = "900000000000000009";
    my $y = "900000000000000007";
    print $x - $y;

will output C<0> on default 32-bit builds, since C<bigrat> never sees the string
literals. To ensure the expression is all treated as C<Math::BigRat> objects,
use a literal number in the expression:

    print +(0+$x) - $y;

=item in_effect()

This method only works on Perl v5.9.4 or later.

=item hex()/oct()

C<bigint> overrides these routines with versions that can also handle big
integer values. Under Perl prior to version v5.9.4, however, this will not
happen unless you specifically ask for it with the two import tags "hex" and
"oct" - and then it will be global and cannot be disabled inside a scope with
"no bigint":

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

    perl -Mbigrat -le 'print sqrt(33)'
    perl -Mbigrat -le 'print 2*255'
    perl -Mbigrat -le 'print 4.5+2*255'
    perl -Mbigrat -le 'print 3/7 + 5/7 + 8/3'
    perl -Mbigrat -le 'print 12->is_odd()';
    perl -Mbigrat=l,GMP -le 'print 7 ** 7777'

=head1 BUGS

For information about bugs and how to report them, see the BUGS section in the
documentation available with the perldoc command.

    perldoc bignum

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc bigrat

For more information, see the SUPPORT section in the documentation available
with the perldoc command.

    perldoc bignum

=head1 LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<bignum> and L<bigint>.

L<Math::BigInt>, L<Math::BigFloat>, L<Math::BigRat> and L<Math::Big> as well as
L<Math::BigInt::FastCalc>, L<Math::BigInt::Pari> and L<Math::BigInt::GMP>.

=head1 AUTHORS

=over 4

=item *

(C) by Tels L<http://bloodgate.com/> in early 2002 - 2007.

=item *

Peter John Acklam E<lt>pjacklam@gmail.comE<gt>, 2014-.

=back

=cut
