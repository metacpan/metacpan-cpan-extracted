
use v5.14;
use warnings;

use require::relative q (test-helper.pl);

note <<'';
Without TEST_LOAD_ROOT, Test::Load::Helper traverses beyond the fixture directory.
- the same test case that silently does nothing when bounded now crosses into t/
- test-helper-die.pl is found in t/ and evaluated, triggering a compile-time die
- Test::Load::Helper surfaces the error via croak

it q (raises an error when traversal crosses into t/ and evaluates test-helper-die.pl)
	=> got    { require::relative::->import (q (fixtures/root-boundary/test-case.pl)) }
	=> throws => expect_re qr (should not have crossed the root boundary)
	;

had_no_warnings;
done_testing;
