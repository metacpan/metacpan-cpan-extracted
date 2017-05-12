#!/usr/bin/perl

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::ASCIITable;
$loaded = 1;
print "ok 1\n";
$i=2;

$t = new Text::ASCIITable({allowHTML => 1});
ok($t->setCols(['Name','Description','Amount']));
ok($t->addRow('Apple',"A fruit. (very tasty!)",4));
$t->addRow('Milk',"You get it from the cows, or the <b>nearest</B> shop.",2);
$t->addRow('Egg','Usually from birds.',6);
eval {
  $content = $t->draw();
};
if (!$@) {ok(undef)} else {ok(1)}
@arr = split(/\n/,$content);
ok(length($arr[4]) > $t->getTableWidth()?undef:1);
ok(length($arr[3]) == $t->getTableWidth()?undef:1);
if (scalar(@arr) == 7) {ok(undef);} else {ok(1);}

sub ok{print(defined(shift)?"not ok $i\n":"ok $i\n");$i++;}
