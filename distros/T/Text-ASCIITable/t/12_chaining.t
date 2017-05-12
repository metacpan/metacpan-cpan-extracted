#!/usr/bin/perl

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::ASCIITable;
$loaded = 1;
print "ok 1\n";
$i=2;
sub ok{print(shift()!=1?"not ok $i\n":"ok $i\n");$i++;}

$tmp = Text::ASCIITable->new({ chaining => 1 })
  ->setCols('One','Two','Three')
  ->addRow([
    [ 1, 2, 3 ],
    [ 4, 5, 6 ],
    [ 7, 8, 9 ],
    ])
  ->draw();
@arr = split(/\n/,$tmp);
ok(length($arr[0]) == 21);
ok(scalar(@arr) == 7);
