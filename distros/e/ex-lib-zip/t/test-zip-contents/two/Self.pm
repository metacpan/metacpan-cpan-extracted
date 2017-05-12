#!perl -w
use strict;
package Self;
use SelfLoader;

1;
__DATA__

sub self {
  "This is the self loaded function";
}
