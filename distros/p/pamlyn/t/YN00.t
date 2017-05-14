# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl PAML.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::Simple tests => 2;
#BEGIN { use_ok('YN00') };
use YN00;
ok(1,'use YN00 fine.');

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# set the argument
@arg = ("abglobin.nuc", 0, 0, 0);

# call the method:
#   pass the argument array - @ary
#   return a reference of array - $x
$x = YN00::cal_kaks(\@arg);
#@kaks_values = @{$x};
$y = @{$x};

# ok() is given an expression.
# If it's true, the test passed. If it's false, it didn't.
# ok() prints out either "ok" or "not ok" along with a test number.
ok ($y == 60, 'Return number fine.');

