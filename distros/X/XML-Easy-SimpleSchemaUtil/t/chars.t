use warnings;
use strict;

use Test::More tests => 1 + 2*12 + 2;
use XML::Easy::NodeBasics 0.007
	qw(xml_content_object xml_content_twine xml_element);

BEGIN { use_ok "XML::Easy::SimpleSchemaUtil", qw(xml_c_chardata); }

my $e0 = xml_element("foo", "bar");
my $e1 = xml_element("baz", "quux");

foreach(
	[ 0, [""] ],
	[ 0, [" "] ],
	[ 0, ["foo"] ],
	[ 0, [" foo"] ],
	[ 0, ["foo "] ],
	[ 0, ["foo bar"] ],
	[ 0, ["a\x{666}b"] ],
	[ 1, [$e0] ],
	[ 1, [$e0," "] ],
	[ 1, [" ",$e0] ],
	[ 1, [$e0,$e1] ],
	[ 1, [$e0," ",$e1] ],
) {
	my($haselems, $in) = @$_;
	foreach my $contentify (\&xml_content_object, \&xml_content_twine) {
		if($haselems) {
			eval { xml_c_chardata($contentify->(@$in)) };
			is $@, "XML schema error: ".
				"subelement where not permitted\n";
		} else {
			is_deeply xml_c_chardata($contentify->(@$in)), $in->[0];
		}
	}
}

eval { xml_c_chardata([]) };
is $@, "invalid XML data: content array has even length\n";
eval { xml_c_chardata("") };
is $@, "invalid XML data: content data isn't a content chunk\n";

1;
