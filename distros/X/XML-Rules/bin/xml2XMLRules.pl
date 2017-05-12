use strict;
use XML::Rules;
use Data::Dumper;

if (!@ARGV) {
	die "Usage: xml2XMLRules examplefile.xml [otherexample.xml ...]
  Generates a set of XML::Rules rules based on one or more example XMLs.
  It's better to provide several examples if you have them in case there
  are any optional attributes or tags that are sometimes, but not always
  repeated.\n"
}

local $Data::Dumper::Terse = 1;
local $Data::Dumper::Indent = 1;
print Dumper(XML::Rules::inferRulesFromExample( @ARGV));