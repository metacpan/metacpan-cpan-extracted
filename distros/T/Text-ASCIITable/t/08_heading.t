#!/usr/bin/perl

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::ASCIITable;
$loaded = 1;
$i=1;
print "ok $i\n";
$i++;
$t = new Text::ASCIITable;
$t->setOptions('headingText','This is a title is too long, so it should expand the table');
$t->setOptions('headingAlign','right');
ok($t->setCols(['id','nick','name']));
ok($t->alignColRight('id'));
ok($t->alignColRight('nick'));
ok($t->addRow(1,'Lunatic-|','Håkon Nessjøen'));
$t->addRow('2','tesepe','William Viker');
$t->addRow('3','espen','Espen Ursin-Holm');
$t->addRow('4','bonde','Martin Mikkelsen');
eval {$content = $t->draw();};
if (!$@) {
  print "ok ".$i."\n"
} else {
  print "not ok ".$i."\n";
}
$i++;
my @arr = split(/\n/,$content);
# check width of title-line against the calculated table width.
if (length($arr[1]) == $t->getTableWidth()) {
  print "ok ".$i."\n";
} else {
  print "not ".$i."\n";
  print STDERR "Error: table has not right width\n";
}
$i++;
$t->setOptions('headingText',"This is a title is actually too long,\nso it should really expand the table a bit");
@arr = split(/\n/,$t);
ok(scalar(@arr) != 11 ? 1 : undef);
ok(length($arr[0]) != 46 ? 1 : undef);

sub ok{print(defined(shift)?"not ok $i\n":"ok $i\n");$i++;}
