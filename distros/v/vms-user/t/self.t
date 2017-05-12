# Before `mmk install' is performed this script should be runnable with
# `mmk test'. After `mmk install' it should work as `perl t/self.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use VMS::User;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

my $a = VMS::User::user_info(getlogin());

print +( defined $a ? '' : 'not '), "ok 2\n";
