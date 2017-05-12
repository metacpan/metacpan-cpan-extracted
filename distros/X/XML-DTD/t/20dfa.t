# -*- cperl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 20dfa.t'

#########################

use Test::More tests => 1 + 6*2 + 26*1;
BEGIN { use_ok('XML::DTD::ContentModel') };

#########################

# Each entry is a triplet consisting of (content model string, array
# of reject example sequences, array of accept example sequences)
my $cmstrvld = [
		[
		 '(a,b,c,d)', ['a,b,c', 'b,c,d', 'a,b,c,d,e'],
		              ['a,b,c,d']
		],
		[
		 '(a?,b?,c?,d?)', ['a,c,b', 'b,c,d,d'],
		                  ['a,b,c,d', 'a,b,c']
		],
		[
		 '(a|b|c|d)', ['a,a', 'a,b'],
		              ['a', 'b', 'c', 'd']
		],
		[
		 '(a|b|c|d)+', ['a,b,e'],
		               ['a', 'a,a', 'a,a,b']
		],
		[
		 '(a,b?,(c|d))', ['a', 'a,b'],
		                 ['a,c', 'a,b,c']
		],
		[
		 '(a,b?,(c|d)+,e*)', ['a', 'b,c'],
		                     ['a,c', 'a,c,c,d']
		]
	       ];

my ($entry, $cm, $cms, $dfa, $rejlst, $acclst, $s);
foreach $entry (@$cmstrvld) {
  $cms = $entry->[0];
  $cm = XML::DTD::ContentModel->new($cms);
  ok(XML::DTD::ContentModel->isa($cm)) or
    diag("Error constructing XML::DTD::ContentModel from $cms\n");
  $dfa = $cm->dfa;
  ok(XML::DTD::Automaton->isa($dfa)) or
    diag("Error constructing DFA from $cms\n");
  $rejlst = $entry->[1];
  foreach $s (@$rejlst) {
    ok(!$dfa->accept([split /,/, $s])) or
      diag("Invalid sequence $s accepted for $cms\n");
  }
  $acclst = $entry->[2];
  foreach $s (@$acclst) {
    ok($dfa->accept([split /,/, $s])) or
      diag("Valid sequence $s rejected for $cms\n");
  }
}
