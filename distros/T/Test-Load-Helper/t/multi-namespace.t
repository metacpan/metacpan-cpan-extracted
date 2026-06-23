
use v5.14;
use warnings;

use require::relative q (test-helper.pl);

note <<'';
Test::Load::Helper loads the same helper file into each package independently.
- the %INC key includes the target package name, so Foo and Bar get separate entries
- the helper is evaluated once per target package, defining the constant in each
- this enables shared fixture files across multiple test packages in a single file

setup_helper_root;

it q (loads helper into Foo and Bar independently via package blocks)
	=> got    { require::relative::->import (q (fixtures/multi-namespace/test-case.pl)) }
	=> expect => expect_all (
		expect_helper_function (q (Foo::multi_namespace_helper_loaded)),
		expect_helper_function (q (Bar::multi_namespace_helper_loaded)),
	);

had_no_warnings;
done_testing;
