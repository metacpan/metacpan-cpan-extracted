
use v5.14;
use warnings;

use require::relative q (test-helper.pl);

note <<'';
Test::Load::Helper loads test-helper.pl found in the same directory as the test case.
- searches from the test case file's own directory upward
- finds the helper immediately, with no traversal needed
- evaluates it into the caller's package namespace (main by default)

setup_helper_root;

it q (loads helper from caller's own directory)
	=> got    { require::relative::->import (q (fixtures/same-dir/test-case.pl)) }
	=> expect => expect_helper_function (q (main::same_dir_helper_loaded))
	;

had_no_warnings;
done_testing;
