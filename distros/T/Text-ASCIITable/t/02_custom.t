#!/usr/bin/perl

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::ASCIITable;
$loaded = 1;
$i=1;
print "ok $i\n";
$i++;

$t = new Text::ASCIITable;
ok($t->setCols(['id','nick','name']));
ok($t->addRow('1','Lunatic-|',"Håkon Nessjøen"));
$t->addRow('2','tesepe','William Viker');
eval {
$content = $t->draw( ['L','R','L','D'],
                     ['L','R','D'],
                     ['L','R','L','D'],
                     ['L','R','D'],
                     ['L','R','L','D']
                    );
};
if (!$@) {
  print "ok ".$i."\n"
} else {
  print "not ok ".$i."\n";
}
$i++;
my @arr = split(/\n/,$content);
if (length($arr[0]) == $t->getTableWidth()) {
  print "ok ".$i."\n"; $i++;
} else {
  print "not ok ".$i."\n";
}

sub ok{print(defined(shift)?"not ok $i\n":"ok $i\n");$i++;}
