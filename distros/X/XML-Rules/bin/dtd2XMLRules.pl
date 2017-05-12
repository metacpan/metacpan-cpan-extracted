use strict;
use XML::Rules;
use Data::Dumper;

my $extended = 0;
if ($ARGV =~ m{^[-/](?:[ex]|extended)$}i) {
	$extended = 1;
	shift(@ARGV);
}

my $file = shift(@ARGV) or die "Usage: dtd2XMLRules [-e | -x |-extended] dtdfile
  Generates a set of XML::Rules rules based on a DTD. The -e or -x or -extended
  controls whether mixed content tags generate 'raw' or 'raw extended' rules.\n";

local $Data::Dumper::Terse = 1;
local $Data::Dumper::Indent = 1;
print Dumper(XML::Rules::inferRulesFromDTD( $file, $extended ));
