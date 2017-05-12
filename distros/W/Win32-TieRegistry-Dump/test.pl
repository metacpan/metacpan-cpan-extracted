# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test;
BEGIN {
	plan tests => 2;
	if ($^O !~ /(mswin32|cygwin)/i){
		print "1..0 skipping all tests - Win32 module on $^O.\n";
		exit;
	}
};
use Win32::TieRegistry::Dump
ok(1); # Loaded okay
$_ = Win32::TieRegistry::Dump::toHash ("LMachine/Software/Microsoft/Windows/CurrentVersion");
ref $_ eq "HASH"? ok(1) : ok(0);

exit;
