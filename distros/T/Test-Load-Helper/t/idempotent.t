
use v5.14;
use warnings;

use require::relative q (test-helper.pl);

note <<'';
Test::Load::Helper evaluates a helper file only once regardless of how many times import is called.
- test case calls "use Test::Load::Helper" twice in the same file
- the helper defines a constant; a second evaluation would cause a redefinition warning
- absence of warnings proves the file was evaluated exactly once

setup_helper_root;

it q (evaluates helper only once even when use Test::Load::Helper is called twice)
	=> got    { require::relative::->import (q (fixtures/idempotent/test-case.pl)) }
	=> expect => expect_helper_function (q (main::idempotent_helper_loaded))
	;

had_no_warnings;
done_testing;
