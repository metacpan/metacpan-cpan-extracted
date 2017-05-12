use strict;
use warnings;

use Test::More tests => 4;
use XML::WBXML qw(xml_to_wbxml);

ok(defined &XML::WBXML::xml_to_wbxml, "found x2w in package");
ok(defined &XML::WBXML::wbxml_to_xml, "found w2x in package");

ok( (defined &xml_to_wbxml), "x2w exported" );
ok( (not defined &wbxml_to_xml), "w2x not exported" );
