package Types::CLike;

use v5.8.8;
use strict;
use warnings;

our $VERSION = '0.91'; # VERSION
# ABSTRACT: C-like data types for Moo(se)

our @EXPORT_OK = ();

use Type::Library -base;
use Types::Numbers;

my $meta = __PACKAGE__->meta;

# All of these types are just aliases of parameterized parents
sub __alias_subtype {
   $meta->add_type(
      name       => $_[0],
      parent     => $_[1],
      library    => __PACKAGE__,
   );
};

sub __integer_builder {
   my ($bits, $signed_names, $unsigned_names) = @_;

   __alias_subtype($_,   Types::Numbers::SignedInt[$bits]) for   @$signed_names;
   __alias_subtype($_, Types::Numbers::UnsignedInt[$bits]) for @$unsigned_names;
};

sub __money_builder {
   my ($bits, $scale, $names) = @_;
   __alias_subtype($_, Types::Numbers::FixedBinary[$bits, $scale]) for @$names;
};

sub __float_builder {
   my ($bits, $ebits, $names) = @_;
   __alias_subtype($_, Types::Numbers::FloatBinary[$bits, $ebits]) for @$names;
};

sub __decimal_builder {
   my ($digits, $emax, $names) = @_;
   __alias_subtype($_, Types::Numbers::FloatDecimal[$digits, $emax]) for @$names;
};

sub __char_builder {
   my ($bits, $names) = @_;
   __alias_subtype($_, Types::Numbers::Char[$bits]) for @$names;
}

### Integer definitions ###
                          # being careful with char here...
__integer_builder(  4, [qw(SNibble SSemiOctet Int4 Signed4)],            [qw(Nibble SemiOctet UInt4 Unsigned4)]),
__integer_builder(  8, [qw(SByte SOctet TinyInt Int8 Signed8)],          [qw(Byte Octet UnsignedTinyInt UInt8 Unsigned8)]),
__integer_builder( 16, [qw(Short SmallInt Int16 Signed16)],              [qw(UShort UnsignedSmallInt UInt16 Unsigned16)]),
__integer_builder( 24, [qw(MediumInt Int24 Signed24)],                   [qw(UnsignedMediumInt UInt24 Unsigned24)]),
__integer_builder( 32, [qw(Int Int32 Signed32)],                         [qw(UInt UnsignedInt UInt32 Unsigned32)]),
__integer_builder( 64, [qw(Long LongLong BigInt Int64 Signed64)],        [qw(ULong ULongLong UnsignedBigInt UInt64 Unsigned64)]),
__integer_builder(128, [qw(SOctaWord SDoubleQuadWord Int128 Signed128)], [qw(OctaWord DoubleQuadWord UInt128 Unsigned128)]),

### "Money" definitions ###
__money_builder( 32, 4, [qw(SmallMoney)]),
__money_builder( 64, 4, [qw(Money Currency)]),
__money_builder(128, 6, [qw(BigMoney)]),

### Float definitions ###
__float_builder( 16,  4, [qw(ShortFloat)]),
__float_builder( 16,  5, [qw(Half Float16 Binary16)]),
__float_builder( 32,  8, [qw(Single Real Float Float32 Binary32)]),
__float_builder( 40,  8, [qw(ExtendedSingle Float40)]),
__float_builder( 64, 11, [qw(Double Float64 Binary64)]),
__float_builder( 80, 15, [qw(ExtendedDouble Float80)]),
__float_builder(104,  8, [qw(Decimal)]),
__float_builder(128, 15, [qw(Quadruple Quad Float128 Binary128)]),

### Decimal definitions ###
__decimal_builder( 7,   96, [ 'Decimal32']),
__decimal_builder(16,  384, [ 'Decimal64']),
__decimal_builder(34, 6144, ['Decimal128']),

### Char definitions ###
__char_builder( 8, [qw(Char Char8)]),
__char_builder(16, [qw(Char16)]),
__char_builder(32, [qw(Char32)]),
__char_builder(48, [qw(Char48)]),
__char_builder(64, [qw(Char64)]),

my %base_tags = (
   'c'       => [qw(Char Byte Short UShort Int UInt Long ULong Float Double ExtendedDouble)],
   'stdint'  => [ map { ('Int'.$_, 'UInt'.$_) } (4,8,16,32,64,128) ],
   'c#'      => [qw(SByte Byte Char16 Short UShort Int UInt Long ULong Float Double Decimal)],
   'ieee754' => ['Binary16', map { ('Binary'.$_, 'Decimal'.$_) } (32,64,128) ],
   'tsql'    => [qw(TinyInt SmallInt Int BigInt SmallMoney Money Float64 Real)],
   'mysql'   => [ (map { ($_, 'Unsigned'.$_) } qw(TinyInt SmallInt MediumInt Int BigInt)), qw(Float Double)],
   'ansisql' => [qw(SmallInt Int Float Real Double)],
);

sub _exporter_expand_tag {
   my $class = shift;
   my ($name, $value, $globals) = @_;

   my $p = '';
   my $base_name = $name;
   $base_name =~ s/^((?:is|assert|to)_|\+)// and $p = $1;

   $base_tags{$base_name} and return map [ "$p$_" => $value ], @{ $base_tags{$base_name} };

   return $class->SUPER::_exporter_expand_tag(@_);
}

42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Types::CLike - C-like data types for Moo(se)

=head1 SYNOPSIS

    package MyPackage;
    use Moo;  # or Moose or Mouse
    use Types::CLike qw(:c);
 
    has 'foo' => (
       isa => Int     # or Int32, Signed32
    );
    has 'bar' => (
       isa => Short   # or SmallInt, Int16, Signed16
    );
 
    use Scalar::Util qw(blessed);
    use Math::BigFloat;
    use Sub::Quote;
 
    has 'baz' => (
       isa => Double,  # or Float64, Binary64
 
       # A Double number gets pretty big, so make sure we use big numbers
       coerce => quote_sub q{
          Math::BigFloat->new($_[0])
             unless (blessed $_[0] =~ /^Math::BigFloat|^bignum/);
       },
    );

=head1 DESCRIPTION

Given the popularity of various byte-sized data types in C-based languages, databases, and computers in general, there's a need for
validating those data types in Perl & Moo(se).  This module covers the gamut of the various number and character types in all of those
forms.

The number types will validate that the number falls within the right bit length, that unsigned numbers do not go below zero, and
"Perl unsafe" numbers are blessed.  Blessed numbers are also checked to make sure they have an accuracy that supports the right number
of significant decimal digits.  (However, BigIntE<sol>Float defaults to 40 digits, which is above the 39 digits for 128-bit numbers, so you
should be safe.)

Char types will validate that it's a single character, using Perl's Unicode-complaint C<<< length >>> function.  The bit check types will
also check that the ASCIIE<sol>Unicode code (C<<< ord >>>) is the right bit length.

IEEE 754 decimal floating types are also available, which are floats that use a base-10 mantissa.  And the SQL Server "money" types,
which are basically decimal numbers stored as integers.

=head1 TYPES

All available types (including lots of aliases) are listed below:

    ### Integers ###
              [SIGNED]                                   | [UNSIGNED]
      4-bit = SNibble SSemiOctet Int4 Signed4            | Nibble SemiOctet UInt4 Unsigned4
      8-bit = SByte SOctet TinyInt Int8 Signed8          | Byte Octet UnsignedTinyInt UInt8 Unsigned8
     16-bit = Short SmallInt Int16 Signed16              | UShort UnsignedSmallInt UInt16 Unsigned16
     24-bit = MediumInt Int24 Signed24                   | UnsignedMediumInt UInt24 Unsigned24
     32-bit = Int Int32 Signed32                         | UInt UnsignedInt UInt32 Unsigned32
     64-bit = Long LongLong BigInt Int64 Signed64        | ULong ULongLong UnsignedBigInt UInt64 Unsigned64
    128-bit = SOctaWord SDoubleQuadWord Int128 Signed128 | OctaWord DoubleQuadWord UInt128 Unsigned128
 
    ### Floats (binary) ###
    (Total, Exponent) bits; Significand precision = Total - Exponent - 1 (sign bit)
 
    ( 16,  4) bits = ShortFloat
    ( 16,  5) bits = Half Float16 Binary16
    ( 32,  8) bits = Single Real Float Float32 Binary32
    ( 40,  8) bits = ExtendedSingle Float40
    ( 64, 11) bits = Double Float64 Binary64
    ( 80, 15) bits = ExtendedDouble Float80
    (104,  8) bits = Decimal    # not a IEEE 754 decimal, but C#'s bizarre "128-bit" float
    (128, 15) bits = Quadruple Quad Float128 Binary128
 
    ### Floats (decimal) ###
    (Digits, Exponent Max)
 
    ( 7,   96) = Decimal32
    (16,  384) = Decimal64
    (34, 6144) = Decimal128
 
    ### "Money" ###
    (Bits, Scale)
 
    ( 32,  4) = SmallMoney
    ( 64,  4) = Money Currency
    (128,  6) = BigMoney  # doesn't exist; might change if it does suddenly exists
 
    ### Chars ###
    Bit check types = Char/Char8, Char16, Char32, Char48, Char64

=head1 EXPORTER TAGS

Since there are so many different aliases in this module, using C<<< :all >>> (while available) probably isn't a good idea.  So, there are
some Exporter tags available, grouped by language:

    # NOTE: Some extra types are included to fill in the gaps for signed vs. unsigned and
    # byte vs. char.
 
    :c       = Char Byte Short UShort Int UInt Long ULong Float Double ExtendedDouble
    :stdint  = Int4 UInt4 ... Int128 UInt128 (except 24-bit)
    :c#      = SByte Byte Char16 Short UShort Int UInt Long ULong Float Double Decimal
    :ieee754 = Binary16,32,64,128 and Decimal32,64,128
    :tsql    = TinyInt SmallInt Int BigInt SmallMoney Money Float64 Real
    :mysql   = TinyInt SmallInt MediumInt Int BigInt (and Unsigned versions) Float Double
    :ansisql = SmallInt Int Float Real Double
 
    :is_*     = All of the is_* functions for that tag
    :to_*     = Same for to_* functions
    :assert_* = Same for assert_* functions
    :+*       = Imports is_*, to_*, assert_*, and types for that tag

=head1 CAVEATS

=head2 Types::Numbers

All of these types are basically aliases of parameterized types in L<Types::Numbers>.  Caveats of those types apply here.  The types
used are as follows:

    SignedInt     # signed integers
    UnsignedInt   # unsigned integers
    FloatBinary   # binary floats
    FloatDecimal  # decimal floats
    FixedBinary   # money types
    Char          # char types

=head2 Type namespace conflicts

Some types are also used by L<Types::Standard> and L<Types::Numbers>, namely C<<< Int >>> and C<<< Char >>>.  So be careful not to import them at
the same time, as they have different meanings.

=head2 Differences between CLike and real data types

Most C-based languages use a C<<< char >>> type to indicate both an 8-bit number and a single character, as all strings in those languages
are represented as a series of character codes.  Perl, as a dynamic language, has a single scalar to represent both strings and
numbers.  Thus, to separate the validation of the two, the term C<<< Byte >>> or C<<< Octet >>> means the numeric 8-bit types, and the term
C<<< Char >>> means the single character string types.

The term C<<< long >>> in CE<sol>C++ is ambiguous depending on the bits of the OS: 32-bits for 32-bit OSs and 64-bits for 64-bit OSs.  Since
the 64-bit version makes more sense (ie: C<<< short < int < long >>>), that is the designation chosen.  To avoid confusion, you can just use
C<<< LongLong >>> and C<<< ULongLong >>>.

The confusion is even worse for float types, with the C<<< long >>> modifier sometimes meaning absolutely nothing in certain hardware
platforms.  C<<< Long >>> isn't even used in this module for those types, in favor of IEEE 754's "Extended" keyword.

=head2 Floats

The floats will support infinity and NaN, since C floats support this.  This may not be desirable, so you might want to subtype the
float and test for InfE<sol>NaN if you don't want these.  Furthermore, the "Perl safe" scalar tests for floats include checks to make sure
it supports InfE<sol>NaN.  However, the odds of it NOT supporting those (since Perl should be using IEEE 754 floats for NV) are practically
zero.

Hopefully, I've covered all possible types of floats found in the wild.  If not, let me know and I'll add it in.  (For that matter, let
me know if I'm missing B<any> type found in the wild.)

=head1 HISTORY

This module started out as L<MooX::Types::CLike>.  Since L<Type::Tiny> came about, that module has been translated to work with TT's
API.  Both L<Types::Numbers> and this module are the result.

=head1 AVAILABILITY

The project homepage is L<https://github.com/SineSwiper/Types-CLike>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Types::CLike/>.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

=over 4

=item *

irc.perl.org

You can connect to the server at 'irc.perl.org' and talk to this person for help: SineSwiper.

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests via L<https://github.com/SineSwiper/Types-CLike/issues>.

=head1 AUTHOR

Brendan Byrd <BBYRD@CPAN.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Brendan Byrd.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
