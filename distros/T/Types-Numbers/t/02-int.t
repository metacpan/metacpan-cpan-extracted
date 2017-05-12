use strict;
use warnings;

use Test::More;
use Types::Numbers ':all';

use lib 't/lib';
use NumbersTest;

my @types = (
     SignedInt[4],   SignedInt[8],   SignedInt[16],   SignedInt[32],   SignedInt[64],   SignedInt[128],
   UnsignedInt[4], UnsignedInt[8], UnsignedInt[16], UnsignedInt[32], UnsignedInt[64], UnsignedInt[128],
    BlessedInt[2],  BlessedInt[3],  BlessedInt[ 5],  BlessedInt[10],  BlessedInt[20],  BlessedInt[ 39],
);

plan tests => scalar @types;

foreach my $type (@types) {
   my $name = $type->display_name;
   $name =~ /^(\w+)\[(\d+)\]/;
   my ($base, $bits) = ($1, $2);

   $bits = ceil($bits / _BASE2_LOG) if ($base eq 'BlessedInt');  # digits to bits

   subtest $name => sub {
      #plan tests => ($base eq 'BlessedInt' ? 15 : 111);

      note explain {
         name => $name,
         inline => $type->inline_check('$num'),
      };

      # Common tests
      numbers_test( undef, $type, 0);
      numbers_test( 'ABC', $type, 0);
      numbers_test(   4.5, $type, 0);
      numbers_test(  $nan, $type, 0);
      numbers_test( $pinf, $type, 0);
      numbers_test( $ninf, $type, 0);
      numbers_test( $Inan, $type, 0);
      numbers_test($Ipinf, $type, 0);
      numbers_test($Ininf, $type, 0);

      numbers_test(     0, $type, $base ne 'BlessedInt');
      numbers_test(     1, $type, $base ne 'BlessedInt');
      numbers_test(    -1, $type, $base eq  'SignedInt');

      numbers_test(   $I0, $type, 1);
      numbers_test(   $I1, $type, 1);
      numbers_test(  $I_1, $type, $base ne 'UnsignedInt');

      # Specific limits
      return if ($base eq 'BlessedInt');   ### TODO: Could probably use some more tests for BlessedInt

      # (trying to minimize the level of automation while still keep some sanity...)
      foreach my $test_bits (4,8,16,24,32,48,64,128) {
         my $spos = 2 ** ($test_bits-1) - 1;  # 8-bit =  127
         my $sneg = -1 - $spos;               # 8-bit = -128
         my $upos = 2 ** $test_bits - 1;      # 8-bit =  255

         note "Bits = $test_bits";

         # -1 = global fail, 0 = use detail below, 1 = global pass
         my $pass = $bits <=> $test_bits;

         # Some tests are unreliable for Perl numbers
         unless ( $test_bits >= int( log(_SAFE_NUM_MAX) / log(2) ) ) {
            if ($base eq 'UnsignedInt') {
               numbers_test($spos+0, $type, $pass || 1);
               numbers_test($sneg-0, $type,          0);
               numbers_test($upos+0, $type, $pass || 1);
               numbers_test($spos+1, $type, $pass || 1);
               numbers_test($sneg-1, $type,          0);
               numbers_test($upos+1, $type, $pass || 0);
            }
            if ($base eq 'SignedInt') {
               numbers_test($spos+0, $type, $pass || 1);
               numbers_test($sneg-0, $type, $pass || 1);
               numbers_test($upos+0, $type, $pass || 0);
               numbers_test($spos+1, $type, $pass || 0);
               numbers_test($sneg-1, $type, $pass || 0);
               numbers_test($upos+1, $type, $pass || 0);
            }
         }

         $pass = $bits <=> $test_bits;
         $spos = $bigtwo->copy ** ($test_bits-1) - 1;  # 8-bit =  127
         $sneg = -1 - $spos;                           # 8-bit = -128
         $upos = $bigtwo->copy ** $test_bits - 1;      # 8-bit =  255

         if ($base eq 'UnsignedInt') {
            numbers_test($spos+0, $type, $pass || 1);
            numbers_test($sneg-0, $type,          0);
            numbers_test($upos+0, $type, $pass || 1);
            numbers_test($spos+1, $type, $pass || 1);
            numbers_test($sneg-1, $type,          0);
            numbers_test($upos+1, $type, $pass || 0);
         }
         if ($base eq 'SignedInt') {
            numbers_test($spos+0, $type, $pass || 1);
            numbers_test($sneg-0, $type, $pass || 1);
            numbers_test($upos+0, $type, $pass || 0);
            numbers_test($spos+1, $type, $pass || 0);
            numbers_test($sneg-1, $type, $pass || 0);
            numbers_test($upos+1, $type, $pass || 0);
         }
      }
   } or diag explain {
      name => $name,
      inline => $type->inline_check('$num'),
   };
}

done_testing;
