package t::ErrorCases;

use warnings;
use strict;

use Params::Classify qw(is_string is_ref);
use Test::More;
use XML::Easy::Content ();
use XML::Easy::Element ();
use t::DataSets (map { ("COUNT_$_", "foreach_$_") } qw(
	no_string
	no_array
	no_hash
	no_string_or_array_or_content_object_or_element
	no_content_object
	no_element
	string_no_name
	string_no_encname
	string_no_chardata
));

use parent "Exporter";
our @EXPORT_OK = map { ("COUNT_$_", "test_$_") } qw(
	error_text
	error_name
	error_type_name
	error_attribute_name
	error_encname
	error_chardata
	error_attributes
	error_content_object
	error_content_twine
	error_content
	error_element
	error_content_item
	error_content_recurse
	error_element_recurse
);

my $c0 = XML::Easy::Content->new([ "bop" ]);
my $e0 = XML::Easy::Element->new("foo", {}, $c0);

sub COUNT_error_text() { COUNT_no_string }
sub test_error_text($) {
	my($func) = @_;
	foreach_no_string sub {
		eval { $func->($_[0]) };
		is $@, "invalid XML data: text isn't a string\n";
	};
}

sub COUNT_error_name() { COUNT_no_string + COUNT_string_no_name }
sub test_error_name($) {
	my($func) = @_;
	foreach_no_string sub {
		eval { $func->($_[0]) };
		is $@, "invalid XML data: name isn't a string\n";
	};
	foreach_string_no_name sub {
		eval { $func->($_[0]) };
		is $@, "invalid XML data: illegal name\n";
	};
}

sub COUNT_error_type_name() { COUNT_no_string + COUNT_string_no_name }
sub test_error_type_name($) {
	my($func) = @_;
	foreach_no_string sub {
		eval { $func->($_[0]) };
		is $@, "invalid XML data: element type name isn't a string\n";
	};
	foreach_string_no_name sub {
		eval { $func->($_[0]) };
		is $@, "invalid XML data: illegal element type name\n";
	};
}

sub COUNT_error_attribute_name() { COUNT_no_string + COUNT_string_no_name }
sub test_error_attribute_name($) {
	my($func) = @_;
	foreach_no_string sub {
		eval { $func->($_[0]) };
		is $@, "invalid XML data: attribute name isn't a string\n";
	};
	foreach_string_no_name sub {
		eval { $func->($_[0]) };
		is $@, "invalid XML data: illegal attribute name\n";
	};
}

sub COUNT_error_encname() { COUNT_no_string + COUNT_string_no_encname }
sub test_error_encname($) {
	my($func) = @_;
	foreach_no_string sub {
		eval { $func->($_[0]) };
		is $@, "invalid XML data: encoding name isn't a string\n";
	};
	foreach_string_no_encname sub {
		eval { $func->($_[0]) };
		is $@, "invalid XML data: illegal encoding name\n";
	};
}

sub COUNT_error_chardata() { COUNT_no_string + COUNT_string_no_chardata }
sub test_error_chardata($) {
	my($func) = @_;
	foreach_no_string sub {
		eval { $func->($_[0]) };
		is $@, "invalid XML data: character data isn't a string\n";
	};
	foreach_string_no_chardata sub {
		eval { $func->($_[0]) };
		is $@, "invalid XML data: ".
			"character data contains illegal character\n";
	};
}

sub COUNT_error_attributes() {
	return COUNT_no_hash + COUNT_error_attribute_name*3 +
		COUNT_error_chardata*2;
}
sub test_error_attributes($) {
	my($func) = @_;
	foreach_no_hash sub {
		eval { $func->($_[0]) };
		is $@, "invalid XML data: attribute hash isn't a hash\n";
	};
	test_error_attribute_name sub {
		die "invalid XML data: attribute name isn't a string\n"
			unless is_string($_[0]);
		$func->({ $_[0] => "quux" });
	};
	test_error_chardata sub { $func->({ z => $_[0] }) };
	test_error_attribute_name sub {
		die "invalid XML data: attribute name isn't a string\n"
			unless is_string($_[0]);
		$func->({ $_[0] => undef });
	};
	test_error_attribute_name sub {
		die "invalid XML data: attribute name isn't a string\n"
			unless is_string($_[0]);
		die "invalid XML data: illegal attribute name\n"
			unless $_[0] lt "\x{d7a3}zzz";
		$func->({
			$_[0] => undef,
			(map { ("\x{d7a3}zzz$_" => undef) } 0..99),
		});
	};
	test_error_chardata sub {
		$func->({
			a => $_[0],
			(map { ("zzz\37$_" => "foo") } 0..99),
		});
	};
}

sub COUNT_error_content_object() { COUNT_no_content_object }
sub test_error_content_object($) {
	my($func) = @_;
	foreach_no_content_object sub {
		eval { $func->($_[0]) };
		is $@, "invalid XML data: content data isn't a content chunk\n";
	};
}

sub COUNT_error_element();
sub test_error_element($);

sub COUNT_error_content_twine() {
	return COUNT_no_array + 4 +
		COUNT_error_chardata*2 + COUNT_error_element*2;
}
sub test_error_content_twine($) {
	my($func) = @_;
	foreach_no_array sub {
		eval { $func->($_[0]) };
		is $@, "invalid XML data: content array isn't an array\n";
	};
	foreach(
		[ ],
		[ "bop", $e0 ],
	) {
		eval { $func->($_) };
		is $@, "invalid XML data: content array has even length\n";
	}
	test_error_chardata sub { $func->([ $_[0] ]) };
	test_error_element sub { $func->([ "a", $_[0], "b" ]) };
	foreach(
		[ "bop", undef ],
		[ undef, $e0 ],
	) {
		eval { $func->($_) };
		is $@, "invalid XML data: content array has even length\n";
	}
	test_error_chardata sub { $func->([ $_[0], undef, "b" ]) };
	test_error_element sub { $func->([ "a", $_[0], undef ]) };
}

sub COUNT_error_content() {
	return COUNT_error_content_object + COUNT_error_content_twine;
}
sub test_error_content($) {
	my($func) = @_;
	test_error_content_object sub {
		die "invalid XML data: content data isn't a content chunk\n"
			if is_ref($_[0], "ARRAY");
		$func->($_[0]);
	};
	test_error_content_twine sub {
		die "invalid XML data: content array isn't an array\n"
			unless is_ref($_[0], "ARRAY");
		$func->($_[0]);
	};
}

sub COUNT_error_element() { COUNT_no_element }
sub test_error_element($) {
	my($func) = @_;
	foreach_no_element sub {
		eval { $func->($_[0]) };
		is $@, "invalid XML data: element data isn't an element\n";
	};
}

sub COUNT_error_content_item() {
	return COUNT_no_string_or_array_or_content_object_or_element +
		COUNT_error_chardata + COUNT_error_content_twine;
}
sub test_error_content_item($) {
	my($func) = @_;
	foreach_no_string_or_array_or_content_object_or_element sub {
		eval { $func->($_[0]) };
		is $@, "invalid XML data: invalid content item\n";
	};
	test_error_chardata sub {
		die "invalid XML data: character data isn't a string\n"
			unless is_string($_[0]);
		$func->($_[0]);
	};
	test_error_content_twine sub {
		die "invalid XML data: content array isn't an array\n"
			unless is_ref($_[0], "ARRAY");
		$func->($_[0]);
	};
}

sub COUNT_error_content_recurse() {
	return COUNT_error_content + COUNT_error_content_twine;
}
sub test_error_content_recurse($) {
	my($func) = @_;
	test_error_content $func;
	test_error_content_twine sub {
		$func->(bless([ $_[0] ], "XML::Easy::Content"));
	};
}

sub COUNT_error_element_recurse() {
	return COUNT_error_element + COUNT_error_type_name*3 +
		COUNT_error_attributes*2 +
		COUNT_error_content_object;
}
sub test_error_element_recurse($) {
	my($func) = @_;
	test_error_element $func;
	test_error_type_name sub {
		$func->(bless([ $_[0], {}, $c0 ], "XML::Easy::Element"));
	};
	test_error_attributes sub {
		$func->(bless([ "foo", $_[0], $c0 ], "XML::Easy::Element"));
	};
	test_error_content_object sub {
		$func->(bless([ "foo", {}, $_[0] ], "XML::Easy::Element"));
	};
	test_error_type_name sub {
		$func->(bless([ $_[0], {}, undef ], "XML::Easy::Element"));
	};
	test_error_type_name sub {
		$func->(bless([ $_[0], undef, $c0 ], "XML::Easy::Element"));
	};
	test_error_attributes sub {
		$func->(bless([ "foo", $_[0], undef ], "XML::Easy::Element"));
	};
}

1;
