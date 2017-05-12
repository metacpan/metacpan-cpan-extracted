#!/usr/bin/perl

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::ASCIITable;
use utf8;
$loaded = 1;
print "ok 1\n";
$i=2;

$t = new Text::ASCIITable({ hide_LastLine => 1, hide_HeadLine => 1 });
ok($t->setCols(['id','nick','name']));
ok($t->addRow('1','Lunatic-|','Håkon Nessjøen'));
$t->addRow('2','tesepe','William Viker');
$t->addRow('3','espen','Espen Ursin-Holm');
$t->addRow('4','bonde','Martin Mikkelsen');
$t->setOptions('hide_HeadRow',1);
$t->setOptions('hide_FirstLine',1);
eval {
  $content = $t->draw();
};
if (!$@) {
  print "ok ".$i."\n"
} else {
  print "not ok ".$i."\n";
}
$i++;
my @arr = split(/\n/,$content);
if (length($arr[0]) == $t->getTableWidth()) {ok(undef);} else {ok(1);}
if (scalar(@arr) == 4) {ok(undef);} else {ok(1)}

sub ok{print(defined(shift)?"not ok $i\n":"ok $i\n");$i++;}
