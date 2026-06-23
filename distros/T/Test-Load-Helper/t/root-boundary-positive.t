
use v5.14;
use warnings;

use require::relative q (test-helper.pl);

note <<'';
Test::Load::Helper respects TEST_LOAD_ROOT and does not cross the boundary.
- test case requests a helper file that exists only above the fixture root (in t/)
- with TEST_LOAD_ROOT set to the fixtures directory, traversal stops before reaching it
- not finding the file is treated as a silent no-op — no error is raised

setup_helper_root;

it q (does not cross root boundary and silently does nothing)
	=> got    { require::relative::->import (q (fixtures/root-boundary/test-case.pl)) }
	=> expect => ignore
	;

had_no_warnings;
done_testing;
