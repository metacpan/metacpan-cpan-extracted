# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Win32::Excel::Refresh') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my $opts = { all => 1 };

# &XLRefresh('C:\Documents and Settings\Christopher Brown\Desktop\CPAN\Win32-Excel-Update\t\book1.xls', $opts);
&XLRefresh('t/book1.xls', $opts);

ok(2);