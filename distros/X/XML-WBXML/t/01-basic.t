use strict;
use warnings;
use Test::More tests => 10;
BEGIN { use_ok('XML::WBXML') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(defined &XML::WBXML::xml_to_wbxml, "found x2w");
my $out = XML::WBXML::xml_to_wbxml("<SyncML></SyncML>");
ok(defined $out);
ok(length $out);
my $wbxml_string = "\x02\xA4\x01\x6a\x00\x2d";
is($out, $wbxml_string);

$out = XML::WBXML::xml_to_wbxml("<SyncML></SyyyyyyncML>");
ok(not defined $out);

ok(defined &XML::WBXML::wbxml_to_xml, "found w2x");
$out = XML::WBXML::wbxml_to_xml($wbxml_string);
ok(defined $out);
ok(length $out);
is($out . "\n", <<END_XML);
<?xml version="1.0"?><!DOCTYPE SyncML PUBLIC "-//SYNCML//DTD SyncML 1.2//EN" "http://www.openmobilealliance.org/tech/DTD/OMA-TS-SyncML_RepPro_DTD-V1_2.dtd"><SyncML xmlns="SYNCML:SYNCML1.2"/>
END_XML
