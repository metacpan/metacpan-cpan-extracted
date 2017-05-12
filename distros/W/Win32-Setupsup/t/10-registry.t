# -*-perl-*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Win32-Setupsup.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test::More tests => 5;

BEGIN { use_ok('Win32::Setupsup') }

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# These aren't very important functions in this module,
# but they're the only ones that are easy to test:

use Win32::TieRegistry ( Delimiter=>"/", ArrayValues=>0 );

my $winReg = $Registry->{'LMachine/Software/Microsoft/Windows/CurrentVersion/'};

my $value;
ok(Win32::Setupsup::GetProgramFilesDir($value));
is($value, $winReg->{ProgramFilesDir});

ok(Win32::Setupsup::GetCommonFilesDir($value));
is($value, $winReg->{CommonFilesDir});
