use strict;
use warnings;

use Test::More;
use Types::Numbers ':all';

use lib 't/lib';
use NumbersTest;

my @types = (
    FloatBinary[16,4], FloatBinary[32,8], FloatBinary[40,8], FloatBinary[64,11], FloatBinary[80,15], FloatBinary[128,15],

   FloatDecimal[3,48], FloatDecimal[7,96], FloatDecimal[8,192], FloatDecimal[16,384], FloatDecimal[21,1536], FloatDecimal[34,6144],
   BlessedFloat[3],    BlessedFloat[7],    BlessedFloat[8],     BlessedFloat[16],     BlessedFloat[21],      BlessedFloat[34],
     BlessedNum[3],      BlessedNum[7],      BlessedNum[8],       BlessedNum[16],       BlessedNum[21],        BlessedNum[34],
);

plan tests => scalar @types;

my %number_cache;

foreach my $type (@types) {
   my $name = $type->display_name;
   $name =~ /^(\w+)\[([\d\,\s]+)\]/;
   my ($base, $params) = ($1, $2);
   my ($bits, $ebits) = split /,\s+/, $params;

   # digits to bits
   my $digits = ceil($bits * _BASE2_LOG);
   unless ($base eq 'FloatBinary') {
      $digits = $bits;
      $bits = ceil($bits / _BASE2_LOG);
   }

   subtest $name => sub {
      plan tests => ($base =~ /Blessed/ ? 62 : 38);

      note explain {
         name => $name,
         #inline => $type->inline_check('$num'),
      };

      # Common tests
      numbers_test( undef, $type, 0);
      numbers_test( 'ABC', $type, 0);

      ### TODO: Move to specific limit section
      #numbers_test(  $nan, $type, $base !~ /Blessed/);
      #numbers_test( $pinf, $type, $base !~ /Blessed/);
      #numbers_test( $ninf, $type, $base !~ /Blessed/);

      numbers_test(   $I1, $type, $base eq 'BlessedNum');
      numbers_test(   $I0, $type, $base eq 'BlessedNum');
      numbers_test(  $I_1, $type, $base eq 'BlessedNum');
      numbers_test( $Inan, $type, $base eq 'BlessedNum');
      numbers_test($Ipinf, $type, $base eq 'BlessedNum');
      numbers_test($Ininf, $type, $base eq 'BlessedNum');

      numbers_test(   $F1, $type, 1);
      numbers_test(   $F0, $type, 1);
      numbers_test(  $F_1, $type, 1);
      numbers_test( $Fnan, $type, 1);
      numbers_test($Fpinf, $type, 1);
      numbers_test($Fninf, $type, 1);

      # Specific limits

      ### TODO: Need tests for non-blessed numbers

      # I hate copying module code for this, but I don't have much of a choice here...
      my $s = 0.0000000000001;
      unless ($base eq 'FloatDecimal') {
         foreach my $args (qw(16_4 32_8 40_8 64_11 80_15 128_15)) {
            my ($test_bits, $test_ebits) = split /_/, $args;
            my $test_sbits = $test_bits - 1 - $test_ebits;  # remove sign bit and exponent bits = significand precision

            my $max = $number_cache{'Binary'.$args};
            unless (defined $max) {
               # MAX = (2 - 2**(-$sbits-1)) * 2**($ebits-1)
               my $emax = $bigtwo->copy->bpow($test_ebits-1)->bsub(1);             # Y = (2**($ebits-1)-1)
               my $smin = $bigtwo->copy->bpow(-$test_sbits-1)->bmul(-1)->badd(2);  # Z = (2 - X) = -X + 2  (where X = 2**(-$sbits-1) )
               $max = $bigtwo->copy->bpow($emax)->bmul($smin);                 # MAX = 2**Y * Z
               $number_cache{$args} = $max;
            }

            # -1 = global fail, 0 = use detail below, 1 = global pass
            my $pass = $bits <=> $test_bits;
            $pass = 1 if ($base =~ /Blessed/);

            numbers_test( $max+ 0, $type, $pass || 1);
            numbers_test(-$max+ 0, $type, $pass || 1);
            numbers_test( $max+$s, $type, $pass || 0);
            numbers_test(-$max-$s, $type, $pass || 0);
         }
      }
      unless ($base eq 'FloatBinary') {
         foreach my $args (qw(3_48 7_96 8_192 16_384 21_1536 34_6144)) {
            my ($test_digits, $test_emax) = split /_/, $args;

            my $max = $number_cache{'Decimal'.$args};
            unless (defined $max) {
               $max = $number_cache{$args} = $bigten->copy->bpow($test_emax)->bmul( '9.'.('9' x ($test_digits-1)) );
            }

            # -1 = global fail, 0 = use detail below, 1 = global pass
            my $pass = $digits <=> $test_digits;
            $pass = 1 if ($base =~ /Blessed/);

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
