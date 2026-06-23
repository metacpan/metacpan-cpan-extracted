
use v5.14;
use warnings;

use require::relative q (test-helper.pl);

note <<'';
A base helper loaded indirectly by two specialised helpers is evaluated only once.
- test-helper-a.pl and test-helper-b.pl each call "use Test::Load::Helper"
- both find and attempt to load the shared test-helper.pl (the base)
- the base is evaluated on the first load; the second attempt hits %INC and is skipped
- absence of a redefinition warning confirms single evaluation

setup_helper_root;

it q (evaluates base helper once even when loaded by two specialised helpers)
	=> got    { require::relative::->import (q (fixtures/indirection-dedup/test-case.pl)) }
	=> expect => expect_all (
		expect_helper_function (q (main::indirection_base_loaded)),
		expect_helper_function (q (main::indirection_a_loaded)),
		expect_helper_function (q (main::indirection_b_loaded)),
	);

had_no_warnings;
done_testing;
