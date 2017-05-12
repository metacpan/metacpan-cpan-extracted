use warnings;
use strict;

use Test::More tests => 1 + 4*14 + 2;
use XML::Easy::NodeBasics 0.007
	qw(xml_content_object xml_content_twine xml_element);

BEGIN { use_ok "XML::Easy::SimpleSchemaUtil", qw(xml_c_subelements); }

my $e0 = xml_element("foo", "bar");
my $e1 = xml_element("baz", "quux");

foreach(
	[ 0, [], [] ],
	[ 0, [$e0], [$e0] ],
	[ 0, [$e0,$e1], [$e0,$e1] ],
	[ 1, [" "], [] ],
	[ 1, [" ",$e0,$e1], [$e0,$e1] ],
	[ 1, [$e0," ",$e1], [$e0,$e1] ],
	[ 1, [$e0,$e1," "], [$e0,$e1] ],
	[ 1, [" \x{9}",$e0,"\x{a}\x{a}",$e1,"\x{d}"], [$e0,$e1] ],
	[ 2, ["a"], [] ],
	[ 2, ["a",$e0,$e1], [$e0,$e1] ],
	[ 2, [$e0,"a",$e1], [$e0,$e1] ],
	[ 2, [$e0,$e1,"a"], [$e0,$e1] ],
	[ 2, ["a",$e0," ",$e1], [$e0,$e1] ],
	[ 2, [" ",$e0,"a",$e1], [$e0,$e1] ],
) {
	my($haschars, $in, $out) = @$_;
	foreach my $contentify (\&xml_content_object, \&xml_content_twine) {
		if($haschars >= 1) {
			eval { xml_c_subelements($contentify->(@$in), 0) };
			is $@, "XML schema error: ".
				"characters where not permitted\n";
		} else {
			is_deeply xml_c_subelements($contentify->(@$in), 0),
				$out;
		}
		if($haschars >= 2) {
			eval { xml_c_subelements($contentify->(@$in), 1) };
			is $@, "XML schema error: non-whitespace ".
				"characters where not permitted\n";
		} else {
			is_deeply xml_c_subelements($contentify->(@$in), 1),
				$out;
		}
	}
}

eval { xml_c_subelements([], 0) };
is $@, "invalid XML data: content array has even length\n";
eval { xml_c_subelements("", 0) };
is $@, "invalid XML data: content data isn't a content chunk\n";

1;
