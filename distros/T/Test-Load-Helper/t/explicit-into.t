
use v5.14;
use warnings;

use require::relative q (test-helper.pl);

note <<'';
Test::Load::Helper accepts an "into" argument to direct loading into a specific package.
- helper symbols are defined in the named package, not in the caller's own namespace
- this allows a test file to load helpers into a shared or utility namespace
- the caller's own package remains unaffected

setup_helper_root;

it q (loads helper into the package named by into =>)
	=> got    { require::relative::->import (q (fixtures/explicit-into/test-case.pl)) }
	=> expect => expect_helper_function (q (ExplicitTarget::explicit_into_helper_loaded))
	;

it q (does not define helper symbols in the caller's own namespace)
	=> got    { require::relative::->import (q (fixtures/explicit-into/test-case.pl)) }
	=> expect => ! expect_helper_function (q (main::explicit_into_helper_loaded))
	;

had_no_warnings;
done_testing;
