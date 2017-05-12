use warnings;
use strict;

our @things;
BEGIN {
	@things = qw(
		name encname chardata
		attributes
		content_object content_twine
		content element
	);
}

use t::DataSets (map { ("COUNT_$_", "foreach_$_") }
			map { ("yes_$_", "no_$_") } @things);
use t::ErrorCases (map { ("COUNT_error_$_", "test_error_$_") } @things);

use Test::More;

my $ntests = 4;
foreach(@things) {
	no strict "refs";
	$ntests += &{"COUNT_yes_$_"}() + &{"COUNT_no_$_"}() +
		&{"COUNT_yes_$_"}() + &{"COUNT_error_$_"}();
}
plan tests => $ntests;

$SIG{__WARN__} = sub { die "WARNING: $_[0]" };

use_ok "XML::Easy::Classify", (map { ("is_xml_$_", "check_xml_$_") } @things);

foreach(@things) {
	eval "foreach_yes_$_ sub { ok is_xml_$_(\$_[0]) }; 1" or die $@;
	eval "foreach_no_$_ sub { ok !is_xml_$_(\$_[0]) }; 1" or die $@;
	eval "foreach_yes_$_ sub {
		eval { check_xml_$_(\$_[0]); };
		is \$\@, '';
	}; 1" or die $@;
	eval "test_error_$_ \\&check_xml_$_; 1" or die $@;
}

ok defined(&{"XML::Easy::Classify::is_xml_content_array"});
ok \&{"XML::Easy::Classify::is_xml_content_array"} == \&{"XML::Easy::Classify::is_xml_content_twine"};
use_ok "XML::Easy::Classify", qw(is_xml_content_array);

1;
