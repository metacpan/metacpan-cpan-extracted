
use v5.14;
use warnings;

use require::relative q (test-helper.pl);

note <<'';
A child test-helper.pl may itself use Test::Load::Helper to load its parent.
- the contracts/ subdirectory has its own test-helper.pl that extends the parent
- the child helper calls "use Test::Load::Helper", which traverses up to hierarchical/
- both parent and child constants are available in the test case namespace

setup_helper_root;

it q (loads both child and parent helpers when child test-helper.pl chains upward)
	=> got    { require::relative::->import (q (fixtures/hierarchical/contracts/test-case.pl)) }
	=> expect => expect_all (
		expect_helper_function (q (main::hierarchical_parent_loaded)),
		expect_helper_function (q (main::hierarchical_contracts_loaded)),
	)
	;

had_no_warnings;
done_testing;
