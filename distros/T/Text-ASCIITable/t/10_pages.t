#!/usr/bin/perl

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::ASCIITable;
$loaded = 1;
print "ok 1\n";
$i=2;

$t = new Text::ASCIITable({'outputWidth' => 40});
$t->setCols(['Name','Description','Amount']);
$t->addRow('Apple',"A fruit. (very tasty!)",4);
$t->addRow('Milk',"Testing the page stuff.",2);
$t->addRow('Egg','Usually from birds.',6);
ok($t->pageCount()==2?undef:1);
$out='';
eval {
  for my $side (1..$t->pageCount()) {
    $out .= $t->drawPage($side)."\n";
  }
};
if (!$@) {ok(undef)} else {ok(1)}
@arr = split(/\n/,$out);
if (scalar(@arr) == 15) {ok(undef);} else {ok(1);}

sub ok{print(defined(shift)?"not ok $i\n":"ok $i\n");$i++;}
