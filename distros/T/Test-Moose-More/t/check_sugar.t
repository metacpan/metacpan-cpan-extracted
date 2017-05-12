use strict;
use warnings;

{
    package TestClass;
    use Moose;
}
{
    package TestClass::NotCleaned;
    use Moose;
    no Moose;
}

use Test::Builder::Tester; # tests => 1;
use Test::More;
use Test::Moose::More;

# not ok 1 - TestRole can has
# not ok 2 - TestRole can around
# not ok 3 - TestRole can augment
# not ok 4 - TestRole can inner
# not ok 5 - TestRole can before
# not ok 6 - TestRole can after
# not ok 7 - TestRole can blessed
# not ok 8 - TestRole can confess

# check for sugar in a class that still has it
my $i;
do { $i++; test_out "ok $i - TestClass can $_" }
    for Test::Moose::More::known_sugar();
check_sugar_ok 'TestClass';
test_test 'check_sugar_ok works correctly';

# check for sugar in a class that has none
$i = 0;
do { $i++; test_out "not ok $i - TestClass::NotCleaned can $_"; test_fail(2) }
    for Test::Moose::More::known_sugar();
check_sugar_ok 'TestClass::NotCleaned';
test_test 'check_sugar_ok works correctly on classes without sugar';

# check for no sugar in a class that still has it
$i = 0;
do { $i++; test_out "not ok $i - TestClass cannot $_"; test_fail(2) }
    for Test::Moose::More::known_sugar();
check_sugar_removed_ok 'TestClass';
test_test 'check_sugar_removed_ok works correctly with sugar';

# check for no sugar in a class that has none
$i = 0;
do { $i++; test_out "ok $i - TestClass::NotCleaned cannot $_" }
    for Test::Moose::More::known_sugar();
check_sugar_removed_ok 'TestClass::NotCleaned';
test_test 'check_sugar_removed_ok works correctly w/o sugar';

done_testing;
