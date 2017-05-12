#!/usr/bin/perl -w
# $Id: 01conditional.t,v 1.4 2000/01/26 21:20:25 aqua Exp $

my @templates = (
		 [ '%1 == 1%' => 1 ],
		 [ '%1 == 0%' => '' ],
		 [ '%1 != 1%' => '' ],
		 [ '%1 != 0%' => 1 ],
		 [ '%foo eq "bar"%' => 1 ],
		 [ '%"bar" eq "bar"%' => 1 ],
		 [ '%"bar" eq foo%' => 1 ],
		 [ '%"one" eq "two"%' => '' ],
		 [ '%foo ne "foo"%' => 1],
		 [ '%1 && 1%' => 1 ],
		 [ '%foo && foo%' => 'bar' ],
		 [ '%1 && 1 && 1%' => 1],
		 [ '%foo && bar && 42%' => '42' ],
		 [ '%1 || 0%' => 1 ],
		 [ '%1 && 0%' => 0 ],
		 [ '%if 1%one%if 2% and two%fi%%fi%' => 'one and two' ],
		 [ '%if 1 && 2%one and two%fi%' => 'one and two' ],
		 [ '%if 1%one%if 0% and zero-err%else% and not zero%fi%%fi%',
		   'one and not zero' ],
		 [ '%if 0% zero'.
		   '%elsif 1%'.
		   'not zero but one'.
		   '%else%'.
		   'err'.
		   '%fi%' => 'not zero but one' ],
		 [ '%if foo%foo true%fi%' => 'foo true' ],
		 [ '%if foo && bar%foo and bar%fi%' => 'foo and bar' ],
		 [ '%if foo%%if bar%foo and bar%fi%%fi%' => 'foo and bar' ],
		 [ '%if foo && !bar%err%else%!foo or bar%fi%' => '!foo or bar' ],
		 [ '%if foo%foo%elsif bar%err%else%err%' => 'foo' ],
		 [ '%if !foo%err%elsif foo%foo%else%err%' => 'foo' ],
		 [ '%if !foo%err%elsif !foo%err%else%not not foo%fi%' => 'not not foo' ],
		 [ '%if foo || bar%foo or bar%elsif bar || foo%elsif 1%one%else%err%',
		   'foo or bar' ],
		 [ '%if 0%err%elsif 0%err%elsif 0%err%else%not zero%', 'not zero' ],
		 [ '%if 1% foo %five% bar %fi%', ' foo 5 bar ' ],
		 [ '%if 1==0%foo %five% bar%fi%', '' ],
		 [ '%if zero eq "+0"%eq+0%fi%', '' ],
		 [ '%if zero eq "-0"%eq-0%fi%', '' ],
		 [ '%if (pluszero eq "+0")%eq+0%fi%', 'eq+0' ],
		 [ '%if (minuszero eq "-0")%eq-0%fi%', 'eq-0' ],
		 [ "%if (nonexistent eq '+0')%eq+0%fi%", '' ],
		);


BEGIN {
    $| = 1; print "1..38\n";
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
	  'foo' => 'bar',
	  'bar' => 'foo',
	  'zero' => 0,
          'pluszero' => '+0',
          'minuszero' => '-0',
	  'five' => 5,
	  'numbers' => [ 1, 2, 3 ],
	  'recipe' => { fee => 'fi',
			fo => 'fum',
			bones => 'bread' }
);


#print STDERR $bt->parse(\$templates[$#templates]->[0],\%ov);
#exit;

my $tn = 0;
my $parsed;
for (@templates) {
    open(T1,">/tmp/maketest-00simple-$$-$tn.tmpl") || do {
	warn "/tmp/maketest-00simple-$$-$tn.tmpl: $!";
	print "not ok ".($tn+3)."\n";
	next;
    };
    print T1 $_->[0];
    close T1;    
    $parsed = $bt->parse("/tmp/maketest-00simple-$$-$tn.tmpl",\%ov);
    if ($parsed ne $_->[1]) {
	print STDERR "['$parsed' ne $_->[1] (from $_->[0])]\n";
	print "not ";
    }
    print "ok ".($tn+3)."\n";
    unlink("/tmp/maketest-00simple-$$-$tn.tmpl");
    $tn++;
}


my $ss = "%if cacheablething%twas true%else%twas false%fi%";

print 'not ' unless
  $bt->parse(\$ss,{cacheablething => 1}) eq 'twas true'
  and $bt->parse(\$ss,{ cacheablething => 0}) eq 'twas false';
print "ok ".($tn+++3),"\n";
