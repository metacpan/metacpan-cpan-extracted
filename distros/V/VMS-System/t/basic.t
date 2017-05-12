# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}
use VMS::System;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

@foo = VMS::System::sys_info_names;
if (scalar(@foo) > 0) {
  print "ok 2\n";
} else {
  print "not ok 2\n";
}

$NodeName = VMS::System::get_one_sys_info_item("NODENAME");
$DCLNodeName = `\$write sys\$output f\$getjpi("", "NODENAME")`;
chomp $DCLNodeName;
if ($NodeName ne $DCLNodeName) {
  print "#DCL $DCLNodeName Us $NodeName\n";
  print "not ok 3\n";
} else {
  print "ok 3\n";
}

tie %testhash, VMS::System, $DCLNodeName or print "not ";
print "ok 4\n";

if ($testhash{NODENAME} ne $DCLNodeName) {
    print "#we say $testhash{NODENAME}, DCL sez $DCLNodeName\n"; # 
    print "not ";
}
print "ok 5\n";


if (!defined($foo = VMS::System::get_all_sys_info_items())) {
  print "not ";
};
print "ok 6\n";

$foo->{NODENAME} eq $DCLNodeName ? print "ok 7\n" : print "not ok 7\n";
