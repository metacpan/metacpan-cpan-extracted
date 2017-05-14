#!c:/perl/bin
# Author: Matthew Fenton

use lib './lib';
use Time::Convert;
my $convert = new Time::Convert;
   $REPLY   = $convert->ConvertSecs(time);
print("\n" . $REPLY . "\n");

1;