
require "TEST.pl";
&TEST::init;

print "1..6\n";

#   setup test files
$testfile1 = &TEST::tmpfile_with_name("page.html", <<"EOT");
some stuff
some more stuff
EOT

$testfile1b = &TEST::tmpfile(<<"EOT");
Content-Type: text/html
Content-Length: 27

some stuff
some more stuff
EOT

$testfile2 = &TEST::tmpfile_with_name("page2.html", <<"EOT");
some stuff
<? print "foo bar"; !>
some more stuff
EOT

$testfile3 = &TEST::tmpfile(<<"EOT");
Content-Type: text/html
Content-Length: 35

some stuff
foo bar
some more stuff
EOT

#   test for working forced CGI mode
$tempfile1 = &TEST::tmpfile;
$rc = &TEST::system("../eperl -m c $testfile1 >$tempfile1");
print ($rc == 0 ? "ok\n" : "not ok\n");
$rc = &TEST::system("cmp $testfile1b $tempfile1");
print ($rc == 0 ? "ok\n" : "not ok\n");

#   test for working implicit CGI mode
$tempfile2 = &TEST::tmpfile;
$rc = &TEST::system("PATH_TRANSLATED=$testfile1; export PATH_TRANSLATED; GATEWAY_INTERFACE=CGI/1.1; export GATEWAY_INTERFACE; ../eperl >$tempfile2");
print ($rc == 0 ? "ok\n" : "not ok\n");
$rc = &TEST::system("cmp $testfile1b $tempfile2");
print ($rc == 0 ? "ok\n" : "not ok\n");

#   test if both are equal
$rc = &TEST::system("cmp $tempfile1 $tempfile2");
print ($rc == 0 ? "ok\n" : "not ok\n");

#   test if filter mode actually works for embedded Perl 5 blocks
$tempfile3 = &TEST::tmpfile;
&TEST::system("../eperl -m c $testfile2 >$tempfile3");
$rc = &TEST::system("cmp $tempfile3 $testfile3");
print ($rc == 0 ? "ok\n" : "not ok\n");

#&TEST::cleanup;
sleep(2);

