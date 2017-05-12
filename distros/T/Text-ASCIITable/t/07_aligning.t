#!/usr/bin/perl -w
BEGIN { $| = 1; print "1..37\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::ASCIITable;
$loaded = 1;
print "ok 1\n";
$i=2;

$t = new Text::ASCIITable();

ok(length($t->align("123","left",2)) == 3);
ok(length($t->align("123","right",2)) == 3);
ok(length($t->align("123","center",2)) == 3);
ok(length($t->align("1234","left",2)) == 4);
ok(length($t->align("1234","right",2)) == 4);
ok(length($t->align("1234","center",2)) == 4);

ok(length($t->align("123","left",5)) == 5);
ok(length($t->align("123","right",5)) == 5);
ok(length($t->align("123","center",5)) == 5);
ok(length($t->align("1234","left",5)) == 5);
ok(length($t->align("1234","right",5)) == 5);
ok(length($t->align("1234","center",5)) == 5);

ok(length($t->align("123","left",2,1)) == 2);
ok(length($t->align("123","right",2,1)) == 2);
ok(length($t->align("123","center",2,1)) == 2);
ok(length($t->align("1234","left",2,1)) == 2);
ok(length($t->align("1234","right",2,1)) == 2);
ok(length($t->align("1234","center",2,1)) == 2);

ok(length($t->align("123","left",30)) == 30);
ok(length($t->align("123","right",30)) == 30);
ok(length($t->align("123","center",30)) == 30);
ok(length($t->align("1234","left",30)) == 30);
ok(length($t->align("1234","right",30)) == 30);
ok(length($t->align("1234","center",30)) == 30);

ok(length($t->align("123","left",1030)) == 1030);
ok(length($t->align("123","right",1030)) == 1030);
ok(length($t->align("123","center",1030)) == 1030);
ok(length($t->align("1234","left",1030)) == 1030);
ok(length($t->align("1234","right",1030)) == 1030);
ok(length($t->align("1234","center",1030)) == 1030);

ok(length($t->align("","left",3)) == 3);
ok(length($t->align("","right",3)) == 3);
ok(length($t->align("","center",3)) == 3);
ok(length($t->align(" ","left",3)) == 3);
ok(length($t->align(" ","right",3)) == 3);
ok(length($t->align(" ","center",3)) == 3);

sub ok {print shift() ? "ok ".$i++."\n" : "nok ".$i++."\n"; }
