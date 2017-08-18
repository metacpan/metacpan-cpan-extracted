use strict;
use lib '.';

use XML::Tiny qw(parsefile);
require "t/test_functions";
print "1..1\n";

$^W = 1;
my @encodings = ( "UTF-8", "UTF-16-BE", "UTF-16-LE", "UTF-32-BE", "UTF-32-LE" );

eval { parsefile('t/null-chars.xml') }; # this is encoded in UTF-16
if($@) {
  ok($@ eq "Not well-formed (Illegal low-ASCII chars found)\n", "appropriate error message vomited");
} else {
  ok(1, "huh, you managed to read the file OK, guess your I/O done something clever");
}
