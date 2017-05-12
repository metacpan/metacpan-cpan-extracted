use warnings;
use strict;

use Test::More tests => 1 + 3*10*2 + 2*10 + 2;
use XML::Easy::NodeBasics 0.007 qw(xml_element xml_content_object);

BEGIN {
	use_ok "XML::Easy::SimpleSchemaUtil",
		qw(xml_s_canonise_chars xml_c_canonise_chars);
}

my $t0_string = "\t \tfoo\t \tbar\t \tbaz\t \t";
my $t0_twine = [$t0_string];
my $t0_content = xml_content_object($t0_string);
foreach(
	[ {}, "\t \tfoo\t \tbar\t \tbaz\t \t" ],
	[ {leading_wsp=>"DELETE"}, "foo\t \tbar\t \tbaz\t \t" ],
	[ {leading_wsp=>"COMPRESS"}, " foo\t \tbar\t \tbaz\t \t" ],
	[ {leading_wsp=>"PRESERVE"}, "\t \tfoo\t \tbar\t \tbaz\t \t" ],
	[ {intermediate_wsp=>"DELETE"}, "\t \tfoobarbaz\t \t" ],
	[ {intermediate_wsp=>"COMPRESS"}, "\t \tfoo bar baz\t \t" ],
	[ {intermediate_wsp=>"PRESERVE"}, "\t \tfoo\t \tbar\t \tbaz\t \t" ],
	[ {trailing_wsp=>"DELETE"}, "\t \tfoo\t \tbar\t \tbaz" ],
	[ {trailing_wsp=>"COMPRESS"}, "\t \tfoo\t \tbar\t \tbaz " ],
	[ {trailing_wsp=>"PRESERVE"}, "\t \tfoo\t \tbar\t \tbaz\t \t" ],
) {
	my($options, $result) = @$_;
	is xml_s_canonise_chars($t0_string, $options), $result;
	is_deeply xml_c_canonise_chars($t0_twine, $options), [$result];
	is_deeply xml_c_canonise_chars($t0_content, $options),
		xml_content_object($result);
}

my $t1_string = "\t \t";
my $t1_twine = [$t1_string];
my $t1_content = xml_content_object($t1_string);
foreach(
	[ {}, "\t \t" ],
	[ {leading_wsp=>"DELETE"}, "" ],
	[ {leading_wsp=>"COMPRESS"}, " " ],
	[ {leading_wsp=>"PRESERVE"}, "\t \t" ],
	[ {intermediate_wsp=>"DELETE"}, "\t \t" ],
	[ {intermediate_wsp=>"COMPRESS"}, "\t \t" ],
	[ {intermediate_wsp=>"PRESERVE"}, "\t \t" ],
	[ {trailing_wsp=>"DELETE"}, "" ],
	[ {trailing_wsp=>"COMPRESS"}, " " ],
	[ {trailing_wsp=>"PRESERVE"}, "\t \t" ],
) {
	my($options, $result) = @$_;
	is xml_s_canonise_chars($t1_string, $options), $result;
	is_deeply xml_c_canonise_chars($t1_twine, $options), [$result];
	is_deeply xml_c_canonise_chars($t1_content, $options),
		xml_content_object($result);
}

my $e0 = xml_element("wibble", "wobble");
my $t2_twine = [
	"\t \tfoo\t \tbar\t \t", $e0,
	"\t \tfoo\t \tbar\t \t", $e0,
	"\t \tfoo\t \tbar\t \t",
];
my $t2_content = xml_content_object($t2_twine);
foreach(
	[ {}, [
		"\t \tfoo\t \tbar\t \t", $e0,
		"\t \tfoo\t \tbar\t \t", $e0,
		"\t \tfoo\t \tbar\t \t",
	]],
	[ {leading_wsp=>"DELETE"}, [
		"foo\t \tbar\t \t", $e0,
		"\t \tfoo\t \tbar\t \t", $e0,
		"\t \tfoo\t \tbar\t \t",
	]],
	[ {leading_wsp=>"COMPRESS"}, [
		" foo\t \tbar\t \t", $e0,
		"\t \tfoo\t \tbar\t \t", $e0,
		"\t \tfoo\t \tbar\t \t",
	]],
	[ {leading_wsp=>"PRESERVE"}, [
		"\t \tfoo\t \tbar\t \t", $e0,
		"\t \tfoo\t \tbar\t \t", $e0,
		"\t \tfoo\t \tbar\t \t",
	]],
	[ {intermediate_wsp=>"DELETE"}, [
		"\t \tfoobar", $e0,
		"foobar", $e0,
		"foobar\t \t",
	]],
	[ {intermediate_wsp=>"COMPRESS"}, [
		"\t \tfoo bar ", $e0,
		" foo bar ", $e0,
		" foo bar\t \t",
	]],
	[ {intermediate_wsp=>"PRESERVE"}, [
		"\t \tfoo\t \tbar\t \t", $e0,
		"\t \tfoo\t \tbar\t \t", $e0,
		"\t \tfoo\t \tbar\t \t",
	]],
	[ {trailing_wsp=>"DELETE"}, [
		"\t \tfoo\t \tbar\t \t", $e0,
		"\t \tfoo\t \tbar\t \t", $e0,
		"\t \tfoo\t \tbar",
	]],
	[ {trailing_wsp=>"COMPRESS"}, [
		"\t \tfoo\t \tbar\t \t", $e0,
		"\t \tfoo\t \tbar\t \t", $e0,
		"\t \tfoo\t \tbar ",
	]],
	[ {trailing_wsp=>"PRESERVE"}, [
		"\t \tfoo\t \tbar\t \t", $e0,
		"\t \tfoo\t \tbar\t \t", $e0,
		"\t \tfoo\t \tbar\t \t",
	]],
) {
	my($options, $result) = @$_;
	is_deeply xml_c_canonise_chars($t2_twine, $options), $result;
	is_deeply xml_c_canonise_chars($t2_content, $options),
		xml_content_object($result);
}

eval { xml_s_canonise_chars("\x{0}", {}) };
is $@, "invalid XML data: character data contains illegal character\n";
eval { xml_s_canonise_chars([""], {}) };
is $@, "invalid XML data: character data isn't a string\n";

1;
