# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;

BEGIN { plan tests => 2 };

use modules (qw(strict warnings 5.006 -force +force -force Data::Dumper) );

ok(1); # If we made it this far, we're ok.

	print Dumper { one => 1, two => 2 };

#use modules (qw(strict warnings 5.006 Data::Dumper -force FAKE::PACKAGE::1 FAKE::PACKAGE::2), { IO::Extended => 'qw(:all)' } );

#	println "IO::Extended ..loaded";

ok(1);

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

