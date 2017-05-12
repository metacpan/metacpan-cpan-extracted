
require "TEST.pl";
&TEST::init;

print "1..2\n";

#
#   TEST 1: plain throughput
#
$tmpfile1 = &TEST::tmpfile(<<'EOT'
foo bar baz quux
öäüÖÄÜß
!"§$%&/()=?`'*+
EOT
);
$tmpfile2 = &TEST::tmpfile;
$rc = &TEST::system("../eperl $tmpfile1 >$tmpfile2");
print ($rc == 0 ? "ok\n" : "not ok\n");

#
#   TEST 2: no difference between input and output
#
$rc = &TEST::system("cmp $tmpfile1 $tmpfile2");
print ($rc == 0 ? "ok\n" : "not ok\n");

&TEST::cleanup;

