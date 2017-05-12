# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 7 };
use Unicode::Decompose qw(normalize);
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

$a = pack("U*", 0xe5, 0x327);
Unicode::Decompose::_decompose($a, "canon");
ok(sprintf("%vx", $a), "61.30a.327");
$a = Unicode::Decompose::order($a);
ok(sprintf("%vx", $a), "61.327.30a");
$a = pack("U*", 0xeb);
Unicode::Decompose::_decompose($a, "canon");
ok(sprintf("%vx", $a), "65.308");
$a = Unicode::Decompose::recompose($a);
ok(sprintf("%vx", $a), "eb");

ok(normalize(pack("U*",0xe5, 0x327)), pack("U*",0x61,0x327,0x30a));
ok(normalize(pack("U*",0xeb)),pack("U*", 0xeb));
