
require "TEST.pl";
&TEST::init;

print "1..6\n";

#   setup test files

$testfile1 = &TEST::tmpfile_with_name("page.html", <<"EOT"
some stuff
some more stuff
EOT
);

$testfile1b = &TEST::tmpfile(<<"EOT"
HTTP/1.0 200 OK
Server: XXXX
Date: XXXX
Connection: close
Content-Type: text/html
Content-Length: 27

some stuff
some more stuff
EOT
);
$testfile2 = &TEST::tmpfile_with_name("page2.html", <<"EOT"
some stuff
<? print "foo bar"; !>
some more stuff
EOT
);
$testfile3 = &TEST::tmpfile(<<"EOT"
HTTP/1.0 200 OK
Server: XXXX
Date: XXXX
Connection: close
Content-Type: text/html
Content-Length: 35

some stuff
foo bar
some more stuff
EOT
);

#   test for working forced NPH-CGI mode
$tempfile1 = &TEST::tmpfile;
$rc = &TEST::system("../eperl -m n $testfile1 | sed -e 's/^Server:.*/Server: XXXX/' -e 's/^Date:.*/Date: XXXX/' >$tempfile1");
print ($rc == 0 ? "ok\n" : "not ok\n");
$rc = &TEST::system("cmp $testfile1b $tempfile1");
print ($rc == 0 ? "ok\n" : "not ok\n");

#   test for working implicit CGI mode
$tempfile2 = &TEST::tmpfile;
$rc = &TEST::system("PATH_TRANSLATED=$testfile1; export PATH_TRANSLATED; GATEWAY_INTERFACE=CGI/1.1; export GATEWAY_INTERFACE; ../eperl -m n | sed -e 's/^Server:.*/Server: XXXX/' -e 's/^Date:.*/Date: XXXX/' >$tempfile2");
print ($rc == 0 ? "ok\n" : "not ok\n");
$rc = &TEST::system("cmp $testfile1b $tempfile2");
print ($rc == 0 ? "ok\n" : "not ok\n");

#   test if both are equal
$rc = &TEST::system("cmp $tempfile1 $tempfile2");
print ($rc == 0 ? "ok\n" : "not ok\n");

#   test if filter mode actually works for embedded Perl 5 blocks
$tempfile3 = &TEST::tmpfile;
&TEST::system("../eperl -m n $testfile2 | sed -e 's/^Server:.*/Server: XXXX/' -e 's/^Date:.*/Date: XXXX/' >$tempfile3");
$rc = &TEST::system("cmp $tempfile3 $testfile3");
print ($rc == 0 ? "ok\n" : "not ok\n");

&TEST::cleanup;

