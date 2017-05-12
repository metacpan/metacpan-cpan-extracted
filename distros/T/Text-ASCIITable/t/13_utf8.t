#!/usr/bin/perl

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::ASCIITable;
use utf8;
$loaded = 1;
print "ok 1\n";
$i=2;

$t = new Text::ASCIITable({utf8 => 1});
$t->setCols(['Name','Description','Amount']);
$t->addRow('Apple',"Hakon Nessjoen",4);
$t->addRow('Apple',"Håkon Nessjoen",4);
$t->addRow('Apple',"Hi this is testest",4);
$t->addRow('Apple',"Håkon Nessjøen",4);
eval {
  $content = $t->draw();
};
if (!$@) {ok(undef)} else {ok(1)}
@arr = split(/\n/,$content);
ok(length($arr[3]) == length($arr[4])?undef:1);
ok(length($arr[3]) == $t->getTableWidth()?undef:1);
ok(length($arr[6]) == $t->getTableWidth()?undef:1);
if (scalar(@arr) == 8) {ok(undef);} else {ok(1);}

sub ok{print(defined(shift)?"not ok $i\n":"ok $i\n");$i++;}
