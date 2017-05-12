# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Win32-Unicode-Shortcut.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;
BEGIN { use_ok('Win32::Unicode::Shortcut') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

foreach (@Win32::Unicode::Shortcut::EXPORT) {
    #
    ## The real test is only to check if it crashes or not
    ## Nevertheless we inform the user is the constant is
    ## defined or not
    #
    my $constant = Win32::Unicode::Shortcut::constant($_);
    if (defined($constant)) {
	# diag("$_ value is $constant");
	isnt($constant, undef, $_);
    } else {
	# diag("$_ is not defined (harmless)");
	is($constant, undef, $_);
    }
}

plan tests => 1 + scalar(@Win32::Unicode::Shortcut::EXPORT);
