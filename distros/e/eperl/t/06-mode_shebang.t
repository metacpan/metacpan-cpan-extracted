
require "TEST.pl";
&TEST::init;

print "1..3\n";

#   setup test files

$testfile1 = &TEST::tmpfile_with_name("page.cgi", <<"EOT"
#!../eperl -mc
some stuff
some more stuff
EOT
);

$testfile1b = &TEST::tmpfile(<<"EOT"
Content-Type: text/html
Content-Length: 27

some stuff
some more stuff
EOT
);

$testfile2 = &TEST::tmpfile_with_name("page2.cgi", <<"EOT"
#!../eperl -mc
some stuff
<? print "foo bar"; !>
some more stuff
EOT
);

$testfile2b = &TEST::tmpfile(<<"EOT"
Content-Type: text/html
Content-Length: 35

some stuff
foo bar
some more stuff
EOT
);

#   test for working forced CGI mode
$tempfile1 = &TEST::tmpfile;
$rc = &TEST::system("chmod a+x $testfile1; ./$testfile1 >$tempfile1");
print ($rc == 0 ? "ok\n" : "not ok\n");
$rc = &TEST::system("cmp $testfile1b $tempfile1");
print ($rc == 0 ? "ok\n" : "not ok\n");

#   test if filter mode actually works for embedded Perl 5 blocks
$tempfile2 = &TEST::tmpfile;
&TEST::system("chmod a+x $testfile2; ./$testfile2 >$tempfile2");
$rc = &TEST::system("cmp $testfile2b $tempfile2");
print ($rc == 0 ? "ok\n" : "not ok\n");

&TEST::cleanup;

