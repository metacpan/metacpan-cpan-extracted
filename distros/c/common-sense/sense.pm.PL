#! perl-000

our $VERSION = 3.74;

open STDOUT, ">$ARGV[0]~"
   or die "$ARGV[0]~: $!";

our ($WARN, $H, %H);

use utf8;
use strict qw(subs vars);

BEGIN {
   if ($] >= 5.010) {
      require feature;
      feature->import (qw(say state switch));
   }
   if ($] >= 5.012) {
      feature->import (qw(unicode_strings));
   }
   if ($] >= 5.016) {
      feature->import (qw(current_sub fc evalbytes));
      feature->unimport (qw(array_base));
   }

}

no warnings;
use warnings qw(FATAL closed threads internal debugging pack malloc portable prototype
                inplace io pipe unpack glob digit printf
                layer reserved taint closure semicolon);
no warnings qw(exec newline unopened);

BEGIN {
   $H    = $^H;
   $WARN = ${^WARNING_BITS};
   %H    = %^H;
}

while (<DATA>) {
   if (/^IMPORT/) {
      print "   # use warnings\n";
      printf "   \${^WARNING_BITS} ^= \${^WARNING_BITS} ^ \"%s\";\n",
             join "", map "\\x$_", unpack "(H2)*", $WARN;
      print "   # use strict, use utf8; use feature;\n";
      printf "   \$^H |= 0x%x;\n", $H;

      if (my @features = grep /^feature_/, keys %H) {
         print "   \@^H{qw(@features)} = (1) x ", (scalar @features), ";\n";
      }
   } elsif (/^VERSION/) {
      print "our \$VERSION = $VERSION;\n";
   } else {
      print;
   }
}

close STDOUT;
rename "$ARGV[0]~", $ARGV[0];

__DATA__
package common::sense;

VERSION

# overload should be included

sub import {
   local $^W; # work around perl 5.16 spewing out warnings for next statement
IMPORT
}

1
