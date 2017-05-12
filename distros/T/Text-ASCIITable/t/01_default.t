#!/usr/bin/perl

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::ASCIITable;
$loaded = 1;
$i=1;
print "ok $i\n";
$i++;
$t = new Text::ASCIITable;
ok($t->setCols(['id','nick','name']));
ok($t->alignColRight('id'));
ok($t->alignColRight('nick'));
ok($t->addRow(1,'Lunatic-|','Håkon Nessjøen'));
$t->addRow('2','tesepe','William Viker');
$t->addRow('3','espen','Espen Ursin-Holm');
$t->addRowLine();
$t->addRow('4','bonde','Martin Mikkelsen');
eval {
  $content = $t->draw();
};
if (!$@) {
  print "ok ".$i."\n"
} else {
	print STDERR $@;
  print "not ok ".$i."\n";
}
$i++;
my @arr = split(/\n/,$content);
if (length($arr[0]) == $t->getTableWidth()) {
  print "ok ".$i."\n";
} else {
  print "not ".$i."\n";
}
$i++;
if (scalar(@arr) == 9) { print "ok ".$i."\n"; } else { print "not ".$i."\n"; }
sub ok{print(defined(shift)?"not ok $i\n":"ok $i\n");$i++;}
