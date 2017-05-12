#!perl

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Unix::Sysexits') };


my $fail = 0;
foreach my $constname (qw(
	EX_CANTCREAT EX_CONFIG EX_DATAERR EX_IOERR EX_NOHOST EX_NOINPUT
	EX_NOPERM EX_NOUSER EX_OK EX_OSERR EX_OSFILE EX_PROTOCOL EX_SOFTWARE
	EX_TEMPFAIL EX_UNAVAILABLE EX_USAGE EX__BASE EX__MAX)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Unix::Sysexits macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

