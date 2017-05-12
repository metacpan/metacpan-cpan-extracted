# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN {print "1..4\n";}
END {print "not ok 1\n" unless $loaded;}
use HP200LX::DB;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

unless ($db= &HP200LX::DB::openDB ('test.gdb'))
{
  print "not ok 2\n";
  exit (0);
}

print "ok 2\n";

unless (tie (@db, HP200LX::DB, $db))
{
  print "not ok 3\n";
  exit (0);
}

print "ok 3\n";

$rec= $db[0];
$keys= join (':', keys %$rec);
$s_keys= 'Opt1:Sel1:Opt2:Text:Note:Sel2:Number:Note&nr:Category:Date:Time';

print $keys, "\n";
unless ($keys eq $s_keys)
{
  print "no ok 4\n";
}
print "ok 4\n";
