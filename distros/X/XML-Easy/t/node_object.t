use warnings;
use strict;

use t::DataSets (map { ("COUNT_$_", "foreach_$_") } qw(
	yes_name
	yes_attributes
	yes_content_twine
));
use t::ErrorCases (map { ("COUNT_$_", "test_$_") } qw(
	error_type_name
	error_attribute_name
	error_attributes
	error_content_twine
	error_content
));

use Test::More tests => 2 +
	3*COUNT_yes_content_twine +
	COUNT_error_content_twine +
	3*COUNT_yes_name + 5*COUNT_yes_attributes + 6*COUNT_yes_content_twine +
	COUNT_error_type_name + COUNT_error_attributes + COUNT_error_content +
	2*COUNT_error_type_name + COUNT_error_attributes +
	COUNT_yes_name +
	COUNT_error_attribute_name;

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

use_ok "XML::Easy::Content";
use_ok "XML::Easy::Element";

my $c0 = XML::Easy::Content->new([ "bop" ]);
my $e0 = XML::Easy::Element->new("foo", {}, $c0);

foreach_yes_content_twine sub { my($twine) = @_;
	my $c = XML::Easy::Content->new($twine);
	is ref($c), "XML::Easy::Content";
	is_deeply $c->twine, $twine;
	is_deeply $c->content, $twine;
};

test_error_content_twine sub { XML::Easy::Content->new($_[0]) };

foreach_yes_name sub { my($name) = @_;
	my $e = XML::Easy::Element->new($name, {}, $c0);
	is ref($e), "XML::Easy::Element";
	is_deeply +XML::Easy::Element->new($name, {}, [ "bop" ]), $e;
	is $e->type_name, $name;
};
foreach_yes_attributes sub { my($attr) = @_;
	my $e = XML::Easy::Element->new("foo", $attr, $c0);
	is ref($e), "XML::Easy::Element";
	is_deeply +XML::Easy::Element->new("foo", $attr, [ "bop" ]), $e;
	is_deeply $e->attributes, $attr;
	is $e->attribute("foo"), $attr->{foo};
	is $e->attribute("bar"), $attr->{bar};
};
foreach_yes_content_twine sub { my($twine) = @_;
	my $e = XML::Easy::Element->new("foo", {}, $twine);
	is ref($e), "XML::Easy::Element";
	is_deeply +XML::Easy::Element->new("foo", {},
				XML::Easy::Content->new($twine)),
		$e;
	is ref($e->content_object), "XML::Easy::Content";
	is_deeply $e->content_object->twine, $twine;
	is_deeply $e->content_twine, $twine;
	is_deeply $e->content, $twine;
};

test_error_type_name sub { XML::Easy::Element->new($_[0], {}, $c0) };
test_error_attributes sub { XML::Easy::Element->new("foo", $_[0], $c0) };
test_error_content sub { XML::Easy::Element->new("foo", {}, $_[0]) };

test_error_type_name sub { XML::Easy::Element->new($_[0], {}, undef) };
test_error_type_name sub { XML::Easy::Element->new($_[0], undef, $c0) };
test_error_attributes sub { XML::Easy::Element->new("foo", $_[0], undef) };

foreach_yes_name sub { is $e0->attribute($_[0]), undef };

test_error_attribute_name sub { $e0->attribute($_[0]) };

1;
