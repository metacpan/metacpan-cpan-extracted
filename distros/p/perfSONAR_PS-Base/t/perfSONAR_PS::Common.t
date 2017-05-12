use Test::More 'no_plan';
use Data::Compare qw( Compare );
use XML::LibXML;

print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";

use_ok('perfSONAR_PS::Common');
use perfSONAR_PS::Common;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Common::readXML tests
$xml = readXML("./t/testfiles/blank");
is($xml, "", "Common::readXML - Empty file read");

$xml = readXML("./t/testfiles/doesnotexist");
is($xml, "", "Common::readXML - Non-existant file read");

$xml = readXML("./t/testfiles/blankXML");
is($xml, "", "Common::readXML - Blank XML file read");

$xml = readXML("./t/testfiles/noXMLTagSmall");
is($xml, "<a b=\"c\"><d/></a>\n", "Common::readXML - Small XML no XML tag");

$xml = readXML("./t/testfiles/smallXML");
is($xml, "<a b=\"c\"><d/></a>\n", "Common::readXML - Small XML");

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Commmon::chainMetadata

print "TODO: Testing for Common::chainMetadata\n";

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Common::genuid

$val = genuid();
ok(defined $val, "Common::genuid - Defined val");

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Common::reMap

print "TODO: Testing for Common::reMap\n";

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";

