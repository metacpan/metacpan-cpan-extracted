use Test::More tests => 16;
use Test::Builder::Tester;

use Test::Smart::Question;

BEGIN { use_ok("Test::Smart") }

ok(defined(&get_yes),'get_yes exported');
ok(defined(&get_no),'get_no exported');
ok(defined(&initialize),'initialize exported');

ok(initialize('Test::Smart::Interface::Mock',answer=>'yes',comment=>'test'),'Initializes an interface');

test_out("ok 1 - test");
get_yes('Test','test');
test_test("get_yes returns an ok with the answer yes");

test_out("not ok 1 - test bad");
test_fail(+2);
test_diag("Got: yes Expected: no\n# Commentary: test");
get_no('Test','test bad');
test_test("get_no fails and produces proper diagnostics when provided yes");

my $Qobj = Test::Smart::ask('Asking','question');
ok($Qobj->isa('Test::Smart::Question'),"ask provides proper question objects");
$Qobj->answer('yes');
test_out("ok 1 - question");
Test::Smart::answer($Qobj,'yes');
test_test("answer responds to proper question objects");

ok(initialize('Test::Smart::Interface::Mock',answer=>'no',comment=>'test'),'Re-initializes an interface');

test_out("ok 1 - test");
get_no('Test','test');
test_test("get_no returns an ok with the answer no");

test_out("not ok 1 - test bad");
test_fail(+2);
test_diag("Got: no Expected: yes\n# Commentary: test");
get_yes('Test','test bad');
test_test("get_yes fails and produces proper diagnostics when provided no");

initialize('Test::Smart::Interface::Mock',skip=>'Skipping');

test_out("ok 1 # skip Skipping");
get_yes('Should skip','skipped question');
test_test("skip functions properly");

initialize('Test::Smart::Interface::Mock',error=>'Failure');

test_out("ok 1 # skip Interface Error: Failure");
get_yes('Should skip','skipped question');
test_test("handles interface error on submit");

test_out("ok 1 # skip Invalid Question");
Test::Smart::answer(undef,'no');
test_test("answer handles bad question objects");

test_out("ok 1 # skip Interface Error: Failure");
Test::Smart::answer($Qobj,'yes');
test_test("answer handles interface errors");
