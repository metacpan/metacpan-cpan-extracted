use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::TypeTiny ();

use Types::Numbers 'Char';

# We can't just blindly make up FFFFFF characters; UTF-8 has a specific standard
my $chars = {
    6 => chr 0x24,
    7 => chr 0x7F,
    8 => chr 0xFF,
   16 => chr 0xC2A2,
   24 => chr 0xE282AC,
   32 => chr 0xF0A4ADA2,
};

sub char_test {
   my ($val, $type, $is_pass) = @_;

   my $msg = sprintf("%s: %s 0x%x",
      $type->display_name,
      ($is_pass ? 'accepts' : 'rejects'),
      ord $val
   );

   my $result = $is_pass ?
      Test::TypeTiny::should_pass($val, $type, $msg) :
      Test::TypeTiny::should_fail($val, $type, $msg)
   ;
   my $error_msg = $type->validate($val);
   diag $error_msg if ($error_msg && !$result);
}

# Char[48]/Char[64] is going to accept every single character, because UTF-8 tops out at 6 bytes.
# Ditto for Char[32], since UTF-8 currently doesn't have anything beyond the U+1003FF codepage.
foreach my $bits (4,6,7,8,16,24,32,48,64,9999) {
   my $type = $bits == 9999 ? Char : Char[$bits];
   my $name = $type->display_name;

   subtest $name => sub {
      note explain {
         name => $name,
         inline => $type->inline_check('$num'),
      };

      Test::TypeTiny::should_fail('ABC', $type, "$name: rejects ABC");

      foreach my $cb (sort { $a <=> $b } keys %$chars) {
         my $c = $chars->{$cb};
         char_test($c, $type, $bits >= $cb);
      }
   } or diag explain {
      name => $name,
      inline => $type->inline_check('$num'),
   };
}

done_testing;
