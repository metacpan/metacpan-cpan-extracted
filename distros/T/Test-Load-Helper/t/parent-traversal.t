
use v5.14;
use warnings;

use require::relative q (test-helper.pl);

note <<'';
Test::Load::Helper walks up the directory tree when no helper exists in the caller's own directory.
- test case lives in a subdirectory with no test-helper.pl of its own
- helper is found one level up, in the parent directory
- it is evaluated into the caller's namespace as if found locally

setup_helper_root;

it q (loads helper from parent directory when none exists locally)
	=> got    { require::relative::->import (q (fixtures/parent-traversal/subdir/test-case.pl)) }
	=> expect => expect_helper_function (q (main::parent_traversal_helper_loaded))
	;

had_no_warnings;
done_testing;
