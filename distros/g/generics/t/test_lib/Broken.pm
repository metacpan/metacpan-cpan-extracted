
package Broken;

use strict;
use warnings;

@Broken::ISA = qw(Base);

use generics inherit => "Base";

use generics params => qw(TEST);

1;

__DATA__