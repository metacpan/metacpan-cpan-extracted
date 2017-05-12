#!perl

# Name: while (<>) { ... } loop
# Require: 4
# Desc:
#


require 'benchlib.pl';

$file = "test-$$.txt";

open(FILE, ">$file") || die;

$lines = 3000;
while ($lines--) {

    if (rand() > 0.2) {
        print FILE qq(localhost - - [08/Oct/1997:11:00:59 +0200] "GET /apache-status HTTP/1.0" 200 205\n);
    } else {
        print FILE qq(localhost - - [08/Oct/1997:11:00:59 +0200] "POST /rubish HTTP/1.0" 202 205\n);
    }
}
close(FILE);




&runtest(0.01, <<'ENDTEST');

   open(FILE, $file) || die "Can't open $file: $!";
   while (<FILE>) {
       next unless /"GET\s+(\s+)/;
       $url = $1;
   }
   close(FILE);

ENDTEST

unlink($file);
