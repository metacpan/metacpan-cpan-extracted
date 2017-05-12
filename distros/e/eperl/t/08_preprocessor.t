
require "TEST.pl";
&TEST::init;

print "1..2\n";

#   setup test files

$testfile1 = &TEST::tmpfile_with_name("file1", <<"EOT");
foo
#include file2
quux
EOT

$testfile2 = &TEST::tmpfile_with_name("file2", <<"EOT");
bar1
#include <file3>
bar3
EOT

$testfile3 = &TEST::tmpfile_with_name("file3", <<"EOT");
bar2
EOT

$testfile4 = &TEST::tmpfile(<<"EOT");
foo
bar1
bar2
bar3
quux
EOT

$x = $testfile2;
$x = $testfile3;
$tempfile5 = &TEST::tmpfile;
$rc = &TEST::system("../eperl -P $testfile1 >$tempfile5");
print ($rc == 0 ? "ok\n" : "not ok\n");
$rc = &TEST::system("cmp $testfile4 $tempfile5");
print ($rc == 0 ? "ok\n" : "not ok\n");

&TEST::cleanup;

