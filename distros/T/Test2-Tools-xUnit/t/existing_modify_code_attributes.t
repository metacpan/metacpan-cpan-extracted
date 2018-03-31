sub MODIFY_CODE_ATTRIBUTES { $::called = 1; () }

use Test2::Tools::xUnit;
use Test2::V0;

sub test : Test { ok $::called }

done_testing;
