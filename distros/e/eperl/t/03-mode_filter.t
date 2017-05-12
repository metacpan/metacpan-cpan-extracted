
require "TEST.pl";
&TEST::init;

print "1..6\n";

#   setup test files
$testfile1 = &TEST::tmpfile(<<"EOT"
some stuff
some more stuff
EOT
);
$testfile2 = &TEST::tmpfile(<<"EOT"
some stuff
<: print "foo bar"; :>
some more stuff
EOT
);
$testfile3 = &TEST::tmpfile(<<"EOT"
some stuff
foo bar
some more stuff
EOT
);

#   test for working forced filter mode
$tempfile1 = &TEST::tmpfile;
$rc = &TEST::system("../eperl -m f $testfile1 >$tempfile1");
print ($rc == 0 ? "ok\n" : "not ok\n");
$rc = &TEST::system("cmp $testfile1 $tempfile1");
print ($rc == 0 ? "ok\n" : "not ok\n");

#   test for working implicit filter mode
$tempfile2 = &TEST::tmpfile;
$rc = &TEST::system("../eperl $testfile1 >$tempfile2");
print ($rc == 0 ? "ok\n" : "not ok\n");
$rc = &TEST::system("cmp $testfile1 $tempfile2");
print ($rc == 0 ? "ok\n" : "not ok\n");

#   test if both are equal
$rc = &TEST::system("cmp $tempfile1 $tempfile2");
print ($rc == 0 ? "ok\n" : "not ok\n");

#   test if filter mode actually works for embedded Perl 5 blocks
$tempfile3 = &TEST::tmpfile;
&TEST::system("../eperl -B '<:' -E ':>' $testfile2 >$tempfile3");
$rc = &TEST::system("cmp $tempfile3 $testfile3");
print ($rc == 0 ? "ok\n" : "not ok\n");

&TEST::cleanup;

