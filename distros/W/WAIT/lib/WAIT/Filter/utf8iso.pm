package WAIT::Filter::utf8iso;
# in a different package so older perls can use WAIT too without utf8 support

use utf8;

sub utf8iso {
  my $s = shift;
  $s =~ tr/\x{80}-\x{ff}//UC;
  $s;
}

# Don't know if needed, AK
# sub dutf8iso {
#   $_[0] =~ tr/\0-\x{ff}//UC;
#   $_[0];
# }

1;
