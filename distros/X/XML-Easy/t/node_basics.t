use warnings;
use strict;

use Params::Classify qw(is_ref);
use t::DataSets (map { ("COUNT_$_", "foreach_$_") } qw(
	yes_name
	yes_attributes
	yes_content_twine
	yes_content
	yes_element
));
use t::ErrorCases (map { ("COUNT_$_", "test_$_") } qw(
	error_type_name
	error_attribute_name
	error_attributes
	error_content
	error_element
	error_content_item
));

use Test::More tests => 67 +
	9*COUNT_yes_content_twine + 2*COUNT_yes_name + 4*COUNT_yes_attributes +
	COUNT_error_content_item*12 +
	COUNT_error_type_name*4 + COUNT_error_attributes*5 +
	COUNT_error_content*2 + COUNT_error_element*6 +
	COUNT_error_attribute_name +
	4*36 + 4*COUNT_yes_content + 4*COUNT_yes_element +
	COUNT_error_content*4 + COUNT_error_element*4 +
	3*17;

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

BEGIN {
	use_ok "XML::Easy::NodeBasics", qw(
		xml_content_object xml_content_twine xml_element
		xml_c_content_object xml_c_content_twine
		xml_e_type_name
		xml_e_attributes xml_e_attribute
		xml_e_content_object xml_e_content_twine
		xml_c_equal xml_e_equal xml_c_unequal xml_e_unequal
	);
}

my($ca, $cb);
$cb = $ca = [""];
xml_element("foo", $cb);
ok $cb == $ca;
$cb = $ca = [""];
xml_content_twine($cb);
ok $cb == $ca;
$cb = $ca = [""];
xml_content_object($cb);
ok $cb == $ca;

my $c0 = xml_content_object("bop");
is_deeply xml_content_object("b", "op"), $c0;
is_deeply xml_content_object(["bop"]), $c0;
is_deeply xml_content_object("bo", "", "p"), $c0;
is_deeply xml_content_object(["bo"], [""], "p"), $c0;
is_deeply xml_content_object($c0), $c0;
is_deeply xml_content_object("", $c0, ""), $c0;

is_deeply xml_content_twine("bop"), ["bop"];
is_deeply xml_content_twine(["bop"]), ["bop"];
is_deeply xml_content_twine("b", "op"), ["bop"];
is_deeply xml_content_twine("bo", "", "p"), ["bop"];
is_deeply xml_content_twine(["bo"], [""], "p"), ["bop"];
is_deeply xml_content_twine($c0), ["bop"];
is_deeply xml_content_twine("", $c0, ""), ["bop"];

my $a0 = { bar=>"baz", quux=>"wibble" };
my $e0 = xml_element("foo", $a0, "bop");
is_deeply xml_element("foo", {bar=>"baz"}, "bop", {quux=>"wibble"}), $e0;
is_deeply xml_element("foo", {}, {quux=>"wibble"}, {bar=>"baz"}, "bop"), $e0;
is_deeply xml_element("foo", ["bop"], $a0), $e0;
is_deeply xml_element("foo", "b", "op", $a0), $e0;
is_deeply xml_element("foo", "bo", $a0, "", "p"), $e0;
is_deeply xml_element("foo", $a0, ["bo"], [""], "p"), $e0;
is_deeply xml_element("foo", $c0, $a0), $e0;
is_deeply xml_element("foo", "", $c0, $a0, ""), $e0;

my $c1 = xml_content_object("a", $e0, "b");
is_deeply xml_content_object(["a", $e0, "b"]), $c1;
is_deeply xml_content_object(["a"], $e0, "", "b"), $c1;
is_deeply xml_content_object("a", ["", $e0, ""], "b"), $c1;
is_deeply xml_content_object("a", xml_content_object($e0, "b")), $c1;

is_deeply xml_content_twine("a", $e0, "b"), ["a", $e0, "b"];
is_deeply xml_content_twine(["a", $e0, "b"]), ["a", $e0, "b"];
is_deeply xml_content_twine(["a"], $e0, "", "b"), ["a", $e0, "b"];
is_deeply xml_content_twine("a", ["", $e0, ""], "b"), ["a", $e0, "b"];
is_deeply xml_content_twine("a", xml_content_object($e0, "b")), ["a", $e0, "b"];

my $e1 = xml_element("bar", "a", $e0, "b");
is_deeply xml_element("bar", ["a", $e0, "b"], {}), $e1;
is_deeply xml_element("bar", ["a"], $e0, "", "b"), $e1;
is_deeply xml_element("bar", {}, "a", {}, ["", $e0, ""], "b"), $e1;
is_deeply xml_element("bar", "a", {}, xml_content_object($e0, "b")), $e1;

is_deeply xml_content_twine(), xml_content_twine("");
is_deeply xml_element("foo"), xml_element("foo", "");

foreach_yes_content_twine sub { my($twine) = @_;
	my $c = xml_content_object($twine);
	is ref($c), "XML::Easy::Content";
	is_deeply $c->twine, $twine;
	is_deeply xml_content_object(@$twine), $c;
	is_deeply xml_content_twine($twine), $twine;
	is_deeply xml_content_twine(@$twine), $twine;
};
foreach_yes_content_twine sub { my($twine) = @_;
	my $e = xml_element("foo", $twine);
	is ref($e), "XML::Easy::Element";
	is_deeply $e->content_twine, $twine;
	is_deeply $e->content_object->twine, $twine;
	is_deeply xml_element("foo", @$twine), $e;
};

test_error_content_item \&xml_content_object;
test_error_content_item \&xml_content_twine;
test_error_content_item sub {
	die "invalid XML data: invalid content item\n"
		if is_ref($_[0], "HASH");
	xml_element("foo", $_[0]);
};
test_error_content_item sub { xml_content_object("foo", $_[0]) };
test_error_content_item sub { xml_content_twine("foo", $_[0]) };
test_error_content_item sub {
	die "invalid XML data: invalid content item\n"
		if is_ref($_[0], "HASH");
	xml_element("foo", "foo", $_[0]);
};
test_error_content_item sub { xml_content_object($_[0], "foo") };
test_error_content_item sub { xml_content_twine($_[0], "foo") };
test_error_content_item sub {
	die "invalid XML data: invalid content item\n"
		if is_ref($_[0], "HASH");
	xml_element("foo", $_[0], "foo");
};

test_error_content_item sub { xml_content_object($_[0], []) };
test_error_content_item sub { xml_content_twine($_[0], []) };
test_error_content_item sub {
	die "invalid XML data: invalid content item\n"
		if is_ref($_[0], "HASH");
	xml_element("foo", $_[0], []);
};

foreach_yes_name sub { my($name) = @_;
	my $e = xml_element($name, {}, "bop");
	is ref($e), "XML::Easy::Element";
	is $e->type_name, $name;
};
foreach_yes_attributes sub { my($attr) = @_;
	my $e = xml_element("foo", $attr, "bop");
	is ref($e), "XML::Easy::Element";
	is_deeply $e->attributes, $attr;
	is $e->attribute("foo"), $attr->{foo};
	is $e->attribute("bar"), $attr->{bar};
};

test_error_type_name sub { xml_element($_[0], $c0) };
eval { xml_element("foo", { foo=>"bar", baz=>"quux" }, $c0, {foo=>"bar"}) };
is $@, "invalid XML data: duplicate attribute name\n";
test_error_attributes sub {
	die "invalid XML data: attribute hash isn't a hash\n"
		unless is_ref($_[0], "HASH");
	xml_element("foo", $_[0], $c0);
};
test_error_attributes sub {
	die "invalid XML data: attribute hash isn't a hash\n"
		unless is_ref($_[0], "HASH");
	xml_element("foo", { womble => "foo" }, $_[0], $c0);
};
test_error_attributes sub {
	die "invalid XML data: attribute hash isn't a hash\n"
		unless is_ref($_[0], "HASH");
	xml_element("foo", $_[0], { womble => "foo" }, $c0);
};

test_error_type_name sub { xml_element($_[0], undef) };
test_error_type_name sub { xml_element($_[0], { "foo\0bar" => {} }) };
test_error_type_name sub { xml_element($_[0], {foo=>"bar"}, {foo=>"bar"}) };
eval { xml_element("foo", {foo=>"bar"}, {foo=>"bar"}, undef) };
is $@, "invalid XML data: duplicate attribute name\n";
eval { xml_element("foo", {foo=>"bar"}, undef, {foo=>"bar"}) };
is $@, "invalid XML data: duplicate attribute name\n";
eval { xml_element("foo", undef, {foo=>"bar"}, {foo=>"bar"}) };
is $@, "invalid XML data: duplicate attribute name\n";
eval {
	xml_element("foo", undef, { "foo\0bar" => {} },
		{foo=>"bar"}, {foo=>"bar"});
};
is $@, "invalid XML data: duplicate attribute name\n";
test_error_attributes sub {
	die "invalid XML data: attribute hash isn't a hash\n"
		unless is_ref($_[0], "HASH");
	xml_element("foo", $_[0], undef);
};
test_error_attributes sub {
	die "invalid XML data: attribute hash isn't a hash\n"
		unless is_ref($_[0], "HASH");
	xml_element("foo", undef, $_[0]);
};

is_deeply xml_c_content_object($c0), $c0;
is_deeply xml_c_content_object(["bop"]), $c0;
is_deeply xml_c_content_object($c1), $c1;
is_deeply xml_c_content_object(["a", $e0, "b"]), $c1;

test_error_content \&xml_c_content_object;

is_deeply xml_c_content_twine($c0), ["bop"];
is_deeply xml_c_content_twine(["bop"]), ["bop"];
is_deeply xml_c_content_twine($c1), ["a", $e0, "b"];
is_deeply xml_c_content_twine(["a", $e0, "b"]), ["a", $e0, "b"];

test_error_content \&xml_c_content_twine;

is xml_e_type_name($e0), "foo";
is xml_e_type_name($e1), "bar";

test_error_element \&xml_e_type_name;

is_deeply xml_e_attributes($e0), { bar => "baz", quux => "wibble" };
is_deeply xml_e_attributes($e1), {};

test_error_element \&xml_e_attributes;

is xml_e_attribute($e0, "foo"), undef;
is xml_e_attribute($e0, "bar"), "baz";
is xml_e_attribute($e0, "quux"), "wibble";
is xml_e_attribute($e1, "foo"), undef;
is xml_e_attribute($e1, "bar"), undef;
is xml_e_attribute($e1, "quux"), undef;

test_error_element sub { xml_e_attribute($_[0], "foo") };
test_error_attribute_name sub { xml_e_attribute($e1, $_[0]) };

test_error_element sub { xml_e_attribute($_[0], undef) };

is_deeply xml_e_content_object($e0), $c0;
is_deeply xml_e_content_object($e1), $c1;

test_error_element \&xml_e_content_object;

is_deeply xml_e_content_twine($e0), ["bop"];
is_deeply xml_e_content_twine($e1), [ "a", $e0, "b" ];

test_error_element \&xml_e_content_twine;

foreach(
	[ $c0, $c0 ],
	[ $c0->twine, $c0->twine ],
	[ ["bop"], ["bop"] ],
	[ $c0, $c0->twine ],
	[ $c0, ["bop"] ],
	[ $c0->twine, ["bop"] ],
	[ $c1, $c1 ],
	[ $c1->twine, $c1->twine ],
	[ ["a",$e0,"b"], ["a",$e0,"b"] ],
	[ $c1, $c1->twine ],
	[ $c1, ["a",$e0,"b"] ],
	[ $c1->twine, ["a",$e0,"b"] ],
) {
	my($a, $b) = @$_;
	ok xml_c_equal($a, $b);
	ok xml_c_equal($b, $a);
	ok !xml_c_unequal($a, $b);
	ok !xml_c_unequal($b, $a);
}

foreach(
	[ ["xyz"], $c0 ],
	[ ["bop",$e0,""], $c0 ],
	[ ["xyz",$e0,"b"], $c1 ],
	[ ["a",$e1,"b"], $c1 ],
	[ ["a",$e0,"xyz"], $c1 ],
	[ ["a"], $c1 ],
	[ ["a",$e0,"b",$e0,"c"], $c1 ],
	[ $c0, $c1 ],
) {
	my($a, $b) = @$_;
	ok !xml_c_equal($a, $b);
	ok !xml_c_equal($b, $a);
	ok xml_c_unequal($a, $b);
	ok xml_c_unequal($b, $a);
}

foreach(
	[ $e0, $e0 ],
	[ $e0, xml_element("foo", $a0, "bop") ],
	[ $e1, $e1 ],
	[ $e1, xml_element("bar", "a", $e0, "b") ],
) {
	my($a, $b) = @$_;
	ok xml_e_equal($a, $b);
	ok xml_e_equal($b, $a);
	ok !xml_e_unequal($a, $b);
	ok !xml_e_unequal($b, $a);
}

foreach(
	[ $e0, xml_element("xyz", $a0, "bop") ],
	[ $e0, xml_element("foo", {}, "bop") ],
	[ $e0, xml_element("foo", { %$a0, bar=>"orinoco" }, "bop") ],
	[ $e0, xml_element("foo", { %$a0, quux=>"orinoco" }, "bop") ],
	[ $e0, xml_element("foo", { %$a0, womble=>"orinoco" }, "bop") ],
	[ $e0, xml_element("foo", { bar=>"baz" }, "bop") ],
	[ $e0, xml_element("foo", { quux=>"wibble" }, "bop") ],
	[ $e0, xml_element("foo", $a0, "xyz") ],
	[ $e1, xml_element("xyz", "a", $e0, "b") ],
	[ $e1, xml_element("bar", $a0, "a", $e0, "b") ],
	[ $e1, xml_element("bar", "xyz", $e0, "b") ],
	[ $e0, $e1 ],
) {
	my($a, $b) = @$_;
	ok !xml_e_equal($a, $b);
	ok !xml_e_equal($b, $a);
	ok xml_e_unequal($a, $b);
	ok xml_e_unequal($b, $a);
}

foreach_yes_content sub { my($c) = @_;
	eval { xml_c_equal($c, $c1) }; is $@, "";
	eval { xml_c_equal($c1, $c) }; is $@, "";
	eval { xml_c_unequal($c, $c1) }; is $@, "";
	eval { xml_c_unequal($c1, $c) }; is $@, "";
};
foreach_yes_element sub { my($e) = @_;
	eval { xml_e_equal($e, $e1) }; is $@, "";
	eval { xml_e_equal($e1, $e) }; is $@, "";
	eval { xml_e_unequal($e, $e1) }; is $@, "";
	eval { xml_e_unequal($e1, $e) }; is $@, "";
};

test_error_content sub { xml_c_equal($_[0], $c1) };
test_error_content sub { xml_c_equal($c1, $_[0]) };
test_error_content sub { xml_c_unequal($_[0], $c1) };
test_error_content sub { xml_c_unequal($c1, $_[0]) };
test_error_element sub { xml_e_equal($_[0], $e1) };
test_error_element sub { xml_e_equal($e1, $_[0]) };
test_error_element sub { xml_e_unequal($_[0], $e1) };
test_error_element sub { xml_e_unequal($e1, $_[0]) };

foreach(
	[qw(xml_content xml_content_twine)],
	[qw(xml_c_content xml_c_content_twine)],
	[qw(xml_e_content xml_e_content_twine)],
	[qw(xc xml_content_object)],
	[qw(xct xml_content_twine)],
	[qw(xe xml_element)],
	[qw(xc_cont xml_c_content_object)],
	[qw(xc_twine xml_c_content_twine)],
	[qw(xe_type xml_e_type_name)],
	[qw(xe_attrs xml_e_attributes)],
	[qw(xe_attr xml_e_attribute)],
	[qw(xe_cont xml_e_content_object)],
	[qw(xe_twine xml_e_content_twine)],
	[qw(xc_eq xml_c_equal)],
	[qw(xe_eq xml_e_equal)],
	[qw(xc_ne xml_c_unequal)],
	[qw(xe_ne xml_e_unequal)],
) {
	my($alias, $orig) = @$_;
	no strict "refs";
	ok defined(&{"XML::Easy::NodeBasics::$alias"});
	ok \&{"XML::Easy::NodeBasics::$alias"} == \&{"XML::Easy::NodeBasics::$orig"};
	use_ok "XML::Easy::NodeBasics", $alias;
}

1;
