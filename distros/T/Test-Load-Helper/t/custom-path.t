
use v5.14;
use warnings;

use require::relative q (test-helper.pl);

note <<'';
An explicit file path triggers the full hierarchy from that file's own directory.
- "use Test::Load::Helper file => q (./foo/bar/test-helper.pl)" loads the named file directly
- that helper itself calls "use Test::Load::Helper", traversing up from foo/bar/
- the ancestor test-helper.pl is found at custom-path/ and loaded as well
- both constants are available in the test case namespace

setup_helper_root;

it q (loads named helper and includes its ancestor hierarchy)
	=> got    { require::relative::->import (q (fixtures/custom-path/test-case.pl)) }
	=> expect => expect_all (
		expect_helper_function (q (main::custom_path_ancestor_loaded)),
		expect_helper_function (q (main::custom_path_bar_loaded)),
	)
	;

had_no_warnings;
done_testing;
