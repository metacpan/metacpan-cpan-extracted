#!/usr/bin/perl

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::ASCIITable;
$loaded = 1;
print "ok 1\n";
$i=2;
sub ok{print(shift()!=1?"not ok $i\n":"ok $i\n");$i++;}

my $t = new Text::ASCIITable({headingText => "This is just to \nprove concept", rowLines=>1});
$t->setCols(qw{ en to });

  my $a = new Text::ASCIITable;
  $a->setCols(qw| det var en gang|);
  $a->addRow(qw/en liten okse !/);

push @$t, $a,'';
push @$t, '',$a;
push @$t, +($a) x 2;
$tmp = $t;
@arr = split(/\n/,$tmp);
ok(length($arr[0]) == 65);
ok(scalar(@arr) == 22);
