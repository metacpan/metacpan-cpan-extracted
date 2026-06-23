
use v5.14;
use warnings;

use require::relative q (test-helper.pl);

note <<'';
Test::Load::Helper continues traversing when intermediate directories have no helper.
- test case lives three levels deep with no test-helper.pl in any intermediate directory
- traversal skips a/, a/b/, and a/b/c/ before finding the helper at the root of the fixture
- the helper is evaluated into the caller's namespace regardless of traversal depth

setup_helper_root;

it q (loads helper found after traversing several empty intermediate directories)
	=> got    { require::relative::->import (q (fixtures/hierarchy-gaps/a/b/c/test-case.pl)) }
	=> expect => expect_helper_function (q (main::hierarchy_gaps_helper_loaded))
	;

had_no_warnings;
done_testing;
