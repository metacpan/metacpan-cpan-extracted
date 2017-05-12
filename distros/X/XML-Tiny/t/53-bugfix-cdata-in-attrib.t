use XML::Tiny qw(parsefile);

use strict;
require "t/test_functions";
print "1..2\n";

$^W = 1;

$SIG{__WARN__} = sub { die("Caught a warning, making it fatal:\n\n$_[0]\n"); };

ok(my $xml = parsefile('t/cdata-in-attrib.xml'), "Don't choke on CDATA in attribs");
is($xml->[0]->{attrib}->{value}, "This ship's name", "parse it correctly");
