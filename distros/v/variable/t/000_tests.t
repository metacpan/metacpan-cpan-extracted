# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use variable;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use variable spam => 25;

spam += 17;

print spam == 42 ? "ok 2\n" : "not ok 2\n";

use variable "i";
use variable  array => [qw /aap noot mies wim zus jet/];

my $line = "";
for (i = 0; defined (array -> [i]); i ++) {
    $line .= array -> [i];
}

print $line eq "aapnootmieswimzusjet" ? "ok 3\n" : "not ok 3\n";
