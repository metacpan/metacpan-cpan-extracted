use strict;
use warnings;

use Test::More tests => 1;
BEGIN { 
      eval { require p2; };
      ok ($@, "p2 must fail on p5p perl"); 
};
