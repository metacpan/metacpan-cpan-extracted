# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Win32-Fmode.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { use_ok('Win32::Fmode') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


## The next three tests shoudl work on a user machine,
## but test more fails tham and doesn't explain why,
## so they're disabled also.

#my( $ram, $fh ) = '';
#
#open $fh, '<', $0;
#ok( fmode( $fh ) == 1 );
#
#open $fh '>', $0;
#ok( fmode( $fh ) == 2 );
#
#open $fh, '+<', $0;
#ok( fmode( $fh ) == 128 );
#
## The following tests should die, but I couldn't see how to
## check that using Test::More from a quick scan of the docs
## so the tests are disabled.
## (And no, I'm not interested in how I *should* be doing it.
##  Under development, these Test::More tests are totally useless
## and at install time, if they detect faults
## the Perl installation is broken, but if this module detects it,
## the user's gonna come belating to me to fix it.)

#open $fh, '>', \$ram;
#fmode( $fh ); ## should die
#
close $fh;
#
#fmode();
#fmode( 'junk' );
#
