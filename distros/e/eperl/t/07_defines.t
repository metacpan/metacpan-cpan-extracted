
require "TEST.pl";
&TEST::init;

print "1..2\n";

#   setup test files

$testfile1 = &TEST::tmpfile(<<'EOT');
some stuff
<: print "foo $BAR $QUUX $ENV{'foo'} bar"; :>
some more stuff
EOT

$testfile1b = &TEST::tmpfile(<<"EOT");
some stuff
foo BAZ QU UX FOO bar
some more stuff
EOT

#   test for working forced CGI mode
$tempfile1 = &TEST::tmpfile;
$rc = &TEST::system("../eperl -dBAR=BAZ \"-dQUUX=QU UX\" -Dfoo=FOO $testfile1 >$tempfile1");
print ($rc == 0 ? "ok\n" : "not ok\n");
$rc = &TEST::system("cmp $testfile1b $tempfile1");
print ($rc == 0 ? "ok\n" : "not ok\n");

&TEST::cleanup;

