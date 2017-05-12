use strict;
use warnings;

use Test::More;
use Types::Numbers ':all';

use lib 't/lib';
use NumbersTest;

my @types = (
    FixedBinary[16,2],  FixedBinary[32,4],  FixedBinary[40,4],  FixedBinary[64,4],  FixedBinary[80,5],  FixedBinary[128,6],
   FixedDecimal[ 3,2], FixedDecimal[ 7,4], FixedDecimal[ 8,4], FixedDecimal[16,4], FixedDecimal[21,5], FixedDecimal[ 34,6],
);

plan tests => scalar @types;

foreach my $type (@types) {
   my $name = $type->display_name;
   $name =~ /^(\w+)\[([\d\,\s]+)\]/;
   my ($base, $params) = ($1, $2);
   my ($bits, $scale) = split /,\s+/, $params;

   # digits to bits
   my $digits = ceil($bits * _BASE2_LOG);
   if ($base eq 'FixedDecimal') {
      $digits = $bits;
      $bits = ceil($bits / _BASE2_LOG);
   }

   subtest $name => sub {
      plan tests => 41;

      note explain {
         name => $name,
         #inline => $type->inline_check('$num'),
      };

      # Common tests
      numbers_test( undef, $type, 0);
      numbers_test( 'ABC', $type, 0);

      numbers_test(  $nan, $type, 0);
      numbers_test( $pinf, $type, 0);
      numbers_test( $ninf, $type, 0);

      numbers_test(   $I1, $type, 0);
      numbers_test(   $I0, $type, 0);
      numbers_test(  $I_1, $type, 0);
      numbers_test( $Inan, $type, 0);
      numbers_test($Ipinf, $type, 0);
      numbers_test($Ininf, $type, 0);

      numbers_test(   $F1, $type, 1);
      numbers_test(   $F0, $type, 1);
      numbers_test(  $F_1, $type, 1);
      numbers_test( $Fnan, $type, 0);
      numbers_test($Fpinf, $type, 0);
      numbers_test($Fninf, $type, 0);

      # Specific limits

      ### TODO: Need tests for non-blessed numbers

      # I hate copying module code for this, but I don't have much of a choice here...
      my $s = 0.0000000000001;
      if ($base eq 'FixedBinary') {
         foreach my $args (qw(16_2 32_4 40_4 64_4 80_5 128_6)) {
            my ($test_bits, $test_scale) = split /_/, $args;
            my $test_sbits = $test_bits - 1;

            my $div = $bigten->copy->bpow($test_scale);
            my ($neg, $pos) = (
               # bdiv returns (quo,rem) in list context :/
               scalar $bigtwo->copy->bpow($test_sbits)->bmul(-1)->bdiv($div),
               scalar $bigtwo->copy->bpow($test_sbits)->bsub(1)->bdiv($div),
            );

            # -1 = global fail, 0 = use detail below, 1 = global pass
            my $pass = $bits <=> $test_bits;

            numbers_test($pos+ 0, $type, $pass || 1);
            numbers_test($neg+ 0, $type, $pass || 1);
            numbers_test($pos+$s, $type, $pass || 0);
            numbers_test($neg-$s, $type, $pass || 0);
         }
      }
      if ($base eq 'FixedDecimal') {
         foreach my $args (qw(3_2 7_4 8_4 16_4 21_5 34_6)) {
            my ($test_digits, $test_scale) = split /_/, $args;

            my $div = $bigten->copy->bpow($test_scale);
            my $max = $bigten->copy->bpow($test_digits)->bsub(1)->bdiv($div);

            # -1 = global fail, 0 = use detail below, 1 = global pass
            my $pass = $digits <=> $test_digits;

            numbers_test( $max+ 0, $type, $pass || 1);
            numbers_test(-$max+ 0, $type, $pass || 1);
            numbers_test( $max+$s, $type, $pass || 0);
            numbers_test(-$max-$s, $type, $pass || 0);
         }
      }
   } or diag explain {
      name => $name,
      inline => $type->inline_check('$num'),
   };
}

done_testing;
