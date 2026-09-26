package Text::KDL::XS::Value;

use strict;
use warnings;

use Carp ();
use Scalar::Util ();
use overload ();
use Text::KDL::XS ();

our @CARP_NOT = qw(
    Text::KDL::XS Text::KDL::XS::Document Text::KDL::XS::Emitter
    Text::KDL::XS::Node Text::KDL::XS::Parser
);

my %IS_FIELD = map { $_ => 1 } qw(type kind value type_annotation);
my %IS_TYPE  = map { $_ => 1 } qw(null bool number string);
my %IS_KIND  = map { $_ => 1 } qw(integer float string);

my $INFINITY       = 9**9**9;
my %KEYWORD_NUMBER = ('#inf' => $INFINITY, '#-inf' => -$INFINITY, '#nan' => $INFINITY - $INFINITY);

sub new {
    my ($class, @fields) = @_;
    my $fields = Text::KDL::XS::_parse_named_arguments(__PACKAGE__ . '->new', 'field', \%IS_FIELD, @fields);
    my $type   = $fields->{type};

    Carp::croak(__PACKAGE__ . "->new: 'type' is required") unless defined $type;
    Carp::croak(__PACKAGE__ . "->new: unknown type '$type' (expected null, bool, number or string)")
        unless $IS_TYPE{$type};
    Carp::croak(__PACKAGE__ . "->new: 'kind' is only allowed for numbers")
        if defined $fields->{kind} && $type ne 'number';
    Carp::croak(__PACKAGE__ . "->new: 'type_annotation' must be a string")
        if ref $fields->{type_annotation};

    my %value = (type => $type, kind => undef, value => undef, type_annotation => $fields->{type_annotation});
    if ($type eq 'bool') {
        $value{value} = $fields->{value} ? 1 : 0;
    }
    elsif ($type eq 'string') {
        $value{value} = _text_field('a string', $fields->{value});
    }
    elsif ($type eq 'number') {
        @value{qw(kind value)} = _number_fields($fields->{kind}, $fields->{value});
    }
    return bless \%value, $class;
}

sub type            { $_[0]->{type}            }
sub kind            { $_[0]->{kind}            }
sub type_annotation { $_[0]->{type_annotation} }
sub value           { $_[0]->{value}           }

sub is_null   { $_[0]->{type} eq 'null'   }
sub is_bool   { $_[0]->{type} eq 'bool'   }
sub is_number { $_[0]->{type} eq 'number' }
sub is_string { $_[0]->{type} eq 'string' }

sub as_perl {
    my ($self) = @_;
    return undef if $self->{type} eq 'null';
    return $self->{value} ? 1 : 0 if $self->{type} eq 'bool';
    return $self->{value};
}

sub as_string {
    my ($self) = @_;
    my $type = $self->{type};
    return undef if $type eq 'null';
    return $self->{value} ? 'true' : 'false' if $type eq 'bool';
    return Text::KDL::XS::_float_text($self->{value}) if $type eq 'number' && $self->_kind_is('float');
    return "$self->{value}";
}

sub as_number {
    my ($self) = @_;
    my $type = $self->{type};
    return undef if $type eq 'null';
    return $self->{value} ? 1 : 0 if $type eq 'bool';
    return _number_from_text($self->{value}) if $type eq 'number' && $self->_kind_is('string');
    return _numified($self->{value});
}

sub as_bignum {
    my ($self) = @_;
    my $type = $self->{type};
    return undef if $type eq 'null';
    return $self->{value} ? 1 : 0 if $type eq 'bool';
    Carp::croak(__PACKAGE__ . "::as_bignum: the value is a $type, not a number") unless $type eq 'number';
    return _bignum_from_text($self->as_string);
}

sub _kind_is {
    my ($self, $kind) = @_;
    return defined $self->{kind} && $self->{kind} eq $kind;
}

# The value of a string: a plain scalar, or an object with a string
# conversion, which is stringified once here.
sub _text_field {
    my ($what, $text) = @_;
    Carp::croak(__PACKAGE__ . "->new: $what needs a defined value") unless defined $text;
    return $text unless ref $text;
    Carp::croak(__PACKAGE__ . "->new: cannot use a " . ref($text) . " reference as $what")
        unless Scalar::Util::blessed($text) && overload::Method($text, '""');
    return "$text";
}

# The kind and value of a number, the kind inferred when it is not given.
sub _number_fields {
    my ($kind, $number) = @_;
    $number = _text_field('a number', $number);
    $kind //= _inferred_kind($number);

    Carp::croak(__PACKAGE__ . "->new: unknown kind '$kind' (expected integer, float or string)")
        unless $IS_KIND{$kind};
    Carp::croak(__PACKAGE__ . "->new: '$number' is not an integer from -2**63 to 2**64-1")
        if $kind eq 'integer' && !Text::KDL::XS::_is_native_integer($number);
    Carp::croak(__PACKAGE__ . "->new: '$number' is not a number")
        if $kind eq 'float' && !Scalar::Util::looks_like_number($number);
    Carp::croak(__PACKAGE__ . "->new: '$number' is not a KDL number")
        if $kind eq 'string' && !Text::KDL::XS::_is_number_literal($number);
    return ($kind, $number);
}

# A Perl number is an integer or a float; any other text must be a KDL number
# literal, which is kept verbatim as kind 'string'.
sub _inferred_kind {
    my ($number) = @_;
    my $kind = Text::KDL::XS::_number_kind_of($number);
    return $kind if defined $kind;
    return 'string' if Text::KDL::XS::_is_number_literal($number);
    Carp::croak(__PACKAGE__ . "->new: '$number' is not a number");
}

# A native number from a Perl number or numeric text. A number is returned as
# it is: arithmetic would turn -0.0 into 0.
sub _numified {
    my ($number) = @_;
    return $number if defined Text::KDL::XS::_number_kind_of($number);
    return 0 + $number;
}

# A native number from KDL number text; lossy beyond the range and precision
# of Perl's numbers.
sub _number_from_text {
    my ($text) = @_;
    return $KEYWORD_NUMBER{$text} if exists $KEYWORD_NUMBER{$text};
    (my $digits = $text) =~ tr/_//d;
    my ($sign, $radix, $magnitude) = $digits =~ /\A([+-]?)0([xob])(.+)\z/
        or return _numified($digits);
    no warnings qw(overflow portable);
    my $number = oct($radix eq 'o' ? "0$magnitude" : "0$radix$magnitude");
    return $sign eq '-' ? -$number : $number;
}

# A Math::BigInt for integral KDL number text, a Math::BigFloat otherwise.
sub _bignum_from_text {
    my ($text) = @_;
    require Math::BigInt;
    require Math::BigFloat;

    return Math::BigFloat->binf('+') if $text eq '#inf';
    return Math::BigFloat->binf('-') if $text eq '#-inf';
    return Math::BigFloat->bnan      if $text eq '#nan';

    (my $digits = $text) =~ tr/_//d;
    if (my ($sign, $radix, $magnitude) = $digits =~ /\A([+-]?)0([xob])(.+)\z/) {
        my $number = _bigint_from_radix($radix, $magnitude);
        return $sign eq '-' ? $number->bneg : $number;
    }
    return $digits =~ /[.eE]/ ? Math::BigFloat->new($digits) : Math::BigInt->new($digits);
}

sub _bigint_from_radix {
    my ($radix, $magnitude) = @_;
    return Math::BigInt->new("0x$magnitude") if $radix eq 'x';
    return Math::BigInt->new("0b$magnitude") if $radix eq 'b';
    # Octal goes through the binary form (three bits per digit), which every
    # Math::BigInt version reads.
    return Math::BigInt->new('0b' . join '', map { sprintf '%03b', $_ } split //, $magnitude);
}

1;

__END__

=encoding utf-8

=head1 NAME

Text::KDL::XS::Value - A KDL value: null, boolean, number or string, with optional type annotation

=head1 SYNOPSIS

=for highlighter language=Perl

  my $v = $node->args->[0];             # or $node->prop('key')

  $v->type;             # 'null' | 'bool' | 'number' | 'string'
  $v->kind;             # for numbers: 'integer' | 'float' | 'string'; else undef
  $v->type_annotation;  # e.g. 'u32' for (u32)42, else undef

  $v->is_null;  $v->is_bool;  $v->is_number;  $v->is_string;

  $v->value;            # the raw stored scalar
  $v->as_perl;          # undef | 1/0 | number | string  (best native scalar)
  $v->as_string;        # undef | 'true'/'false' | KDL number text | string
  $v->as_number;        # undef | 1/0 | a native Perl number
  $v->as_bignum;        # undef | 1/0 | Math::BigInt or Math::BigFloat (exact)

  # Constructing values for emit_kdl:
  Text::KDL::XS::Value->new(type => 'null');
  Text::KDL::XS::Value->new(type => 'bool',   value => 1);
  Text::KDL::XS::Value->new(type => 'number', value => 42);             # kind integer
  Text::KDL::XS::Value->new(type => 'number', value => 2.5);            # kind float
  Text::KDL::XS::Value->new(type => 'number', kind => 'string', value => '1e400');
  Text::KDL::XS::Value->new(type => 'string', value => 'text', type_annotation => 'date');

=for highlighter

=head1 DESCRIPTION

Every argument and every property value in a KDL document is one of four
types: null, boolean, number or string, optionally preceded by a
C<(type)> annotation. C<Text::KDL::XS::Value> carries exactly that
information, without coercing it, so that a document can be inspected and
written back without loss.

The object is a blessed hash with the keys C<type>, C<kind>, C<value> and
C<type_annotation>. Editing C<< $v->{value} >> in place is supported and
is the simplest way to change a value before re-emitting; the emitter
checks the edited value the same way L</new> does and dies if it no longer
fits its type and kind.

=head1 VALUE MODEL

  KDL source                  type    kind     value (Perl)        as_perl
  --------------------------  ------  -------  ------------------  ----------
  #null (v1: null)            null    undef    undef               undef
  #true (v1: true)            bool    undef    1                   1
  #false (v1: false)          bool    undef    0                   0
  42, 0xFF, 1_000             number  integer  IV 42, 255, 1000    same
  4294967295,                 number  integer  IV or UV            same
    18446744073709551615
  3.14, 1e3                   number  float    NV 3.14, 1000       same
  #inf #-inf #nan             number  float    Inf, -Inf, NaN      same
  1e400, 3.141592653589793,   number  string   the digits as text  the string
    18446744073709551616
  "text", bare, #"raw"#       string  undef    character string    same

The kind of a number says how it is stored in Perl:

  integer   no decimal point or exponent, and the value lies in
            -2**63 .. 2**64-1 (values above 2**63-1 are unsigned integers)
  float     decimal point or exponent, at most 15 digits written before
            the exponent (leading and trailing zeros count), written
            exponent within -284 .. 284; also #inf, #-inf and #nan. The
            value is the double nearest to the literal.
  string    every other number, as text (underscores removed, radix
            prefixes converted to decimal, leading + dropped, otherwise
            verbatim)

So C<0xFFFFFFFF> and Unix timestamps are integers, while
C<3.141592653589793> (16 digits) and C<18446744073709551616> (2**64)
arrive as C<string>. The float rule is the one of the underlying ckdl
library; a decimal kept as text is exact, see
L</"ARBITRARY PRECISION NUMBERS"> for how to use it.

=head1 CONSTRUCTOR

=head2 new

=for highlighter language=Perl

  my $v = Text::KDL::XS::Value->new(type => $type, %fields);

=for highlighter

The constructor checks its arguments, so that a value that was created
successfully is always written as valid KDL.

=over 4

=item type (required)

One of C<'null'>, C<'bool'>, C<'number'>, C<'string'>. Missing dies with
C<Text::KDL::XS::Value-E<gt>new: 'type' is required>, anything else with
C<Text::KDL::XS::Value-E<gt>new: unknown type 'X' (expected null, bool,
number or string)>.

=item value

The payload, by type:

  null     ignored; the value is always undef
  bool     any Perl value, judged by Perl truthiness (so the string
           'false' means true); stored as 1 or 0
  number   a Perl number, or the number as text (see kind); required
  string   a character string; required

An object with string overloading is stringified once, here. A missing
value for a number or string, and any other reference, die.

=item kind

For numbers only; any other type dies when C<kind> is given. One of:

  integer  a Perl integer, or decimal digits with an optional sign, in the
           range -2**63 .. 2**64-1 (written in decimal)
  float    anything Perl considers numeric (Scalar::Util::looks_like_number);
           written with the shortest text that reads back as the same double
  string   a KDL number literal, written verbatim: an optional sign followed
           by decimal digits with an optional fraction and exponent, or by
           0x, 0o or 0b digits, '_' allowed after the first digit; or one of
           #inf, #-inf and #nan

Without C<kind>, it is inferred from C<value>: a Perl number (a scalar
with a numeric value and no string value, or one whose string value is
exactly Perl's rendering of that number) is C<integer> or C<float>, other
text that is a KDL number literal is C<string>, and anything else dies.

C<'string'> is the way to write arbitrary precision numbers and floats
with exactly the digits you want (see
L<Text::KDL::XS::Cookbook/"Emitting floating point numbers">).

=item type_annotation

Optional C<(type)> annotation string.

=back

Any other field and an odd number of arguments die. C<new> may be called on
a subclass.

=head1 METHODS

=head2 type

C<'null'>, C<'bool'>, C<'number'> or C<'string'>.

=head2 kind

For numbers: C<'integer'>, C<'float'> or C<'string'>. C<undef> for the
other types.

=head2 type_annotation

The C<(type)> annotation written before the value, as a string, or
C<undef>.

=head2 is_null, is_bool, is_number, is_string

True when C<type> is the corresponding type.

=head2 value

The stored scalar exactly as the parser produced it (or as passed to
C<new>): C<undef> for null, C<1>/C<0> for booleans, an integer or
floating point number for numbers, the digit string for numbers of kind
C<string>, the text for strings.

=head2 as_perl

The most natural Perl representation:

  null    -> undef
  bool    -> 1 or 0
  number  -> integer / float (or the digit string for kind 'string')
  string  -> the string

This is what L<Text::KDL::XS::Node/as_data> uses.

=head2 as_string

A string form for display or comparison:

  null    -> undef
  bool    -> 'true' or 'false'
  number  -> integer: the stored value as a string
             float: the text the emitter writes, the shortest one that
             reads back as the same double, always with a decimal point
             or an exponent ('1.0', '1000.0', '0.30000000000000004',
             '1e+21'); '#inf', '#-inf' or '#nan' for the special values
             kind 'string': the stored text
  string  -> the string

=head2 as_number

A native Perl number for arithmetic:

  null    -> undef
  bool    -> 1 or 0
  number  -> the number (kind integer / float, unchanged, -0.0 included);
             for kind 'string' the text converted to a Perl number:
             radix prefixes and underscores are understood, #inf, #-inf
             and #nan give Inf, -Inf and NaN
  string  -> the string numified (a non-numeric string gives 0 and an
             "isn't numeric" warning)

Numbers kept as text are usually too big or too precise for a Perl
number, so the conversion is lossy: integers beyond 2**64 and decimals
with more than about 16 digits lose precision, values beyond the range of
a double become infinite. Use L</as_bignum> for exact arithmetic.

=head2 as_bignum

An exact arbitrary precision number:

  null    -> undef
  bool    -> 1 or 0
  number  -> a Math::BigInt for integral text (kind integer, or kind
             string without a decimal point or exponent), a Math::BigFloat
             otherwise (floats, decimals, #inf, #-inf, #nan)
  string  -> dies

The object is built from the same text as L</as_string>, so a float gives
the decimal it is written as (C<0.1> gives C<0.1>, not the binary value of
the double). L<Math::BigInt> and L<Math::BigFloat> are loaded on first use.

=head1 ARBITRARY PRECISION NUMBERS

Numbers outside the native integer range, and decimals with more digits
than a double holds, have kind C<string> and keep their exact text:

=for highlighter language=Perl

  my $v = parse_kdl("n 123456789012345678901234567890\n")->nodes->[0]->args->[0];
  $v->kind;                  # 'string'
  $v->value;                 # '123456789012345678901234567890'
  $v->as_bignum + 1;         # Math::BigInt 123456789012345678901234567891
  $v->as_number;             # 1.23456789012346e+29 (a double, inexact)

=for highlighter

The stored text is normalised: underscores removed, hexadecimal, octal and
binary literals converted to decimal, a leading C<+> dropped, a C<->
preserved. For decimal literals with a point or exponent the original
spelling is kept (C<1e400>, C<3.141592653589793>).

=head1 SEE ALSO

L<Text::KDL::XS>, L<Text::KDL::XS::Node>, L<Text::KDL::XS::Cookbook/NUMBERS>.

=head1 AUTHOR

Davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 LICENSE

Copyright (C) 2026 Davenonymous.

This Perl distribution is licensed under the same terms as Perl itself.

=cut
