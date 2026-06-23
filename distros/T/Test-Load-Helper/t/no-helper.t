
use v5.14;
use warnings;

use require::relative q (test-helper.pl);

note <<'';
Test::Load::Helper does nothing when no test-helper.pl exists anywhere in the hierarchy.
- traversal is bounded by TEST_LOAD_ROOT, so the search stays within the fixture directory
- no error is raised — the absence of a helper is a valid, silent no-op
- no symbols are injected into the caller's namespace

setup_helper_root;

it q (does not define any helper function in the caller namespace)
	=> got    { require::relative::->import (q (fixtures/no-helper/test-case.pl)) }
	=> expect => ! expect_helper_function (q (main::no_helper_loaded))
	;

had_no_warnings;
done_testing;
