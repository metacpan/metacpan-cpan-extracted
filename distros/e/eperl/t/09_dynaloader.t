
require "TEST.pl";
&TEST::init;

print "1..1\n";

#   setup test files

$testfile1 = &TEST::tmpfile(<<'EOT');
foo
<: 
use Socket; 
$proto = getprotobyname('tcp');
$proto = 0;
:>
quux
EOT

$rc = &TEST::system("../eperl $testfile1 >/dev/null");
print ($rc == 0 ? "ok\n" : "not ok\n");

&TEST::cleanup;

