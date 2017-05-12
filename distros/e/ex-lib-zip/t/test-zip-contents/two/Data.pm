#!perl -w
use strict;
package Data;

sub line {
  chomp (my $line = <DATA>);
  return $line;
}

sub eof {
  return eof DATA;
}

1;

# Make sure there are only 2 lines here, as EOF on <DATA> is tested.
__DATA__
Dromedary
Bactrian
