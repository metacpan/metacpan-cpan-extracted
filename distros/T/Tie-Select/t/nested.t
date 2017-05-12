use strict;
use warnings;

use Test::More tests => 3;

use Tie::Select;

open my $handle1, '>', \my $var1;
open my $handle2, '>', \my $var2;

{
  local $SELECT = $handle1;
  print "Level 1";
  is( $var1, "Level 1", "print to first level, first time" );

  {
    local $SELECT = $handle2;
    print "Level 2";
    is( $var2, "Level 2", "print to second level" );
  }

  print ", Level 1 again";
  is( $var1, "Level 1, Level 1 again", "print to first level, second time" );
}


