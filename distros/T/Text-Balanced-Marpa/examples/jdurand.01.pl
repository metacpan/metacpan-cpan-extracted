#!/usr/bin/env perl

use strict;
use warnings;

use Text::Balanced::Marpa ':constants';

# -------------------------------------

my($parser) = Text::Balanced::Marpa -> new
  (
   open    => ['`'],
   close   => ['\''],
   options => print_warnings,
  );
my(@text)  = (q|`defn(format(``array[%d]'', `$1'))'|);
my($count) = 0;

my($result);

for my $text (@text)
  {
    $count++;
    print "Parsing |$text|\n";
    $result = $parser -> parse(\$text);
    print join("\n", @{$parser -> tree2string}), "\n";
    print "Parse result: $result (0 is success)\n";
    print '-' x 50, "\n";
  }