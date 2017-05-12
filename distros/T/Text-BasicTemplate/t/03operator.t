#!/usr/bin/perl -w
# $Id: 03operator.t,v 1.2 1999/12/17 22:03:23 aqua Exp $

my @templates = (
		 [ '%"foo" eq "foo"%' => 1],
		 [ '%"foo" eq "bar"%' => ''],
		 [ '%"abc" lt "bcd"%' => 1],
		 [ '%"bcd" lt "abc"%' => ''],
		 [ '%"bcd" gt "abc"%' => 1],
		 [ '%"abc" gt "bcd"%' => ''],
		 [ '%"abc" le "bcd"%' => 1],
		 [ '%"abc" ge "bcd"%' => ''],
		 [ '%"bcd" ge "bcd"%' => 1],
		 [ '%"bcd" ge "abc"%' => 1],
		 [ '%"foobar" =~ "foo"%' => 1],
		 [ '%"foobar" =~ "snaf"%' => ''],
		 [ '%"foobar" !~ "snaf"%' => 1],
		 [ '%"foobar" !~ "foo"%' => ''],
		 [ '%"foobar" !~ "foo"%' => ''],

		 [ '%1 == 1%' => '1' ],
		 [ '%foo == 42%' => '1' ],
		 [ '%1 < 2%' => '1' ],
		 [ '%1 <= 2%' => '1' ],
		 [ '%2 <= 2%' => '1' ],
		 [ '%2 > 1%' => '1' ],
		 [ '%2 >= 1%' => '1' ],
		 [ '%2 < 1%' => '' ],
		 [ '%2 <=> 1%' => '1' ],
		 [ '%1 <=> 2%' => '-1' ],

		 [ '%1 && 1%' => 1 ],
		 [ '%1 || 1%' => 1 ],

		 [ '%"foo" . "bar"%' => 'foobar' ],
		 [ '%"foo" x 3%' => 'foofoofoo' ],
		 [ '%2 + 2%' => 4 ],
		 [ '%2 - 2%' => 0 ],
		 [ '%foo / 2%' => 21 ],
		 [ '%5 / 3%' => 5/3 ],
		 [ '%5 * 2%' => 10 ],
		 [ '%31 div 2%' => 15 ],
		 [ '%31 mod 2%' => 1 ],
		 [ '%foo ** 3%' => 42**3 ],
		 [ '%pi ** 3%' => 3.1415927**3 ],
		 [ '%4 ^ 4%' => 0 ],
		 [ '%6 ^ 2%' => 4 ],
		 [ '%6 & 4%' => 4 ],
		 [ '%6 | 4%' => 6 ],
		 [ '%16 & 2%' => 0 ],
		 [ '%1 << 1%' => 2 ],
		 [ '%6 << 2%' => 24 ],
		 [ '%4 << 0%' => 4 ],
		 [ '%0 << 5%' => 0 ],
		 [ '%1 >> 1%' => 0 ],
		 [ '%6 >> 2%' => 1 ],
		 [ '%4 >> 0%' => 4 ],
		 [ '%0 >> 5%' => 0 ],

		 [ '%!0%' => 1 ],
		 [ '%!1%' => '' ],

		 [ '%defined foo%' => 1 ],
		 [ '%defined bar%' => '' ],

		);


BEGIN {
    $| = 1; print "1..57\n";
}
END {print "not ok 1\n" unless $loaded;}
use Text::BasicTemplate;
$loaded = 1;
print "ok 1\n";

use strict;

my $bt = new Text::BasicTemplate;
$bt or print "not ";
print "ok 2\n";

my %ov = (
	  'foo' => 42,
	  'pi' => 3.1415927,
);


#print STDERR $bt->parse(\$templates[$#templates]->[0],\%ov);
#exit;

my $tn = 0;
my $parsed;
my $ss;
for (@templates) {
    $ss = \$_->[0];
    print "not [$$ss =",$bt->parse($ss,\%ov),", not $_->[1]] "
      unless $bt->parse($ss,\%ov) eq $_->[1];
    print "ok ".($tn+3)."\n";
    $tn++;
}
