
require "TEST.pl";
&TEST::init;

print "1..2\n";

#
#   TEST 1: total empty file
#
$tmpfile1 = &TEST::tmpfile("");
$tmpfile2 = &TEST::tmpfile;
&TEST::system("../eperl $tmpfile1 >$tmpfile2");
$rc = &TEST::system("cmp $tmpfile1 $tmpfile2");
print ($rc == 0 ? "ok\n" : "not ok\n");

#
#   TEST 2: file with empty Perl 5 block
#
$tmpfile1 = &TEST::tmpfile(<<'EOT'
foo bar baz quux
foo<::>bar<?!>baz<:   :>quux
foo bar baz quux
EOT
);
$tmpfile2 = &TEST::tmpfile;
$tmpfile3 = &TEST::tmpfile(<<'EOT'
foo bar baz quux
foobar<?!>bazquux
foo bar baz quux
EOT
);
&TEST::system("../eperl -B '<:' -E ':>' $tmpfile1 >$tmpfile2");
$rc = &TEST::system("cmp $tmpfile2 $tmpfile3");
print ($rc == 0 ? "ok\n" : "not ok\n");

&TEST::cleanup;

