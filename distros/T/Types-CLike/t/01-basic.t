use strict;
use warnings;

use Test::More;
use Scalar::Util 'blessed';
use Test::TypeTiny ();
use Types::CLike;

my $types = {
   int4   => [qw(SNibble SSemiOctet Int4 Signed4)],            uint4   => [qw(Nibble SemiOctet UInt4 Unsigned4)],
   int8   => [qw(SByte SOctet TinyInt Int8 Signed8)],          uint8   => [qw(Byte Octet UnsignedTinyInt UInt8 Unsigned8)],
   int16  => [qw(Short SmallInt Int16 Signed16)],              uint16  => [qw(UShort UnsignedSmallInt UInt16 Unsigned16)],
   int24  => [qw(MediumInt Int24 Signed24)],                   uint24  => [qw(UnsignedMediumInt UInt24 Unsigned24)],
   int32  => [qw(Int Int32 Signed32)],                         uint32  => [qw(UInt UnsignedInt UInt32 Unsigned32)],
   int64  => [qw(Long LongLong BigInt Int64 Signed64)],        uint64  => [qw(ULong ULongLong UnsignedBigInt UInt64 Unsigned64)],
   int128 => [qw(SOctaWord SDoubleQuadWord Int128 Signed128)], uint128 => [qw(OctaWord DoubleQuadWord UInt128 Unsigned128)],

   money32  => [qw(SmallMoney)],
   money64  => [qw(Money Currency)],
   money128 => [qw(BigMoney)],

   float16_4   => [qw(ShortFloat)],
   float16_5   => [qw(Half Float16 Binary16)],
   float32_8   => [qw(Single Real Float Float32 Binary32)],
   float40_8   => [qw(ExtendedSingle Float40)],
   float64_11  => [qw(Double Float64 Binary64)],
   float80_15  => [qw(ExtendedDouble Float80)],
   float104_8  => [qw(Decimal)],
   float128_15 => [qw(Quadruple Quad Float128 Binary128)],
};

# Parent tree
my $root = {};
my $tree = {};
my @type_list = map { Types::CLike->$_() } map { @$_ } values %$types;
for (my $i = 0; $i < @type_list; $i++) {
   my $type   = $type_list[$i];
   my $name   = ($type->library || blessed $type).'->'.$type->display_name;
   my $parent = $type->parent;

   $tree->{$name} //= {};

   if ($parent) {
      my $parent_name = ($parent->library || blessed $parent).'->'.$parent->display_name;

      push @type_list, $parent unless ($tree->{$parent_name});

      $tree->{$parent_name} //= {};
      $tree->{$parent_name}{$name} = $tree->{$name};
   }
   else {
      $root->{$name} //= $tree->{$name};
   }
}

diag explain $root;

# A simple set of tests for a simple module

# Integers
foreach my $bits (4,8,16,24,32,64,128) {
   ok_subtype(  Types::Numbers::SignedInt[$bits], Types::CLike->$_() ) for @{ $types->{ "int$bits"} };
   ok_subtype(Types::Numbers::UnsignedInt[$bits], Types::CLike->$_() ) for @{ $types->{"uint$bits"} };
}

# Money
foreach my $p (qw[32_4 64_4 128_6]) {
   my ($bits, $scale) = split(/_/, $p);
   ok_subtype(Types::Numbers::FixedBinary[$bits, $scale], Types::CLike->$_() ) for @{ $types->{"money$bits"} };
}

# Floats
foreach my $p (qw[16_4 16_5 32_8 40_8 64_11 80_15 104_8 128_15]) {
   my ($bits, $ebits) = split(/_/, $p);
   ok_subtype(Types::Numbers::FloatBinary[$bits, $ebits], Types::CLike->$_() ) for @{ $types->{"float$p"} };
}

# Decimals
foreach my $p (qw[32_7_96 64_16_384 128_34_6144]) {
   my ($bits, $digits, $emax) = split(/_/, $p);
   my $type_name = "Decimal$bits";
   ok_subtype(Types::Numbers::FloatDecimal[$digits, $emax], Types::CLike->$type_name() );
}

# Char
ok_subtype(Types::Numbers::Char[8], Types::CLike::Char );
foreach my $bits (8,16,32,48,64) {
   my $type_name = "Char$bits";
   ok_subtype(Types::Numbers::Char[$bits], Types::CLike->$type_name() );
}

done_testing;

sub ok_subtype {
   my ($supertype, $type) = @_;
   Test::TypeTiny::ok_subtype($supertype, $type) ||
      diag join(', ', map { $_->name.($_->name eq $_->display_name ? '' : ' ('.$_->display_name.')') } ($type, $type->parents));
}