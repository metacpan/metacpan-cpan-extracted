# -*- cperl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 20dfa.t'

#########################

use Test::More tests => 1 + 2*13;
BEGIN { use_ok('XML::DTD::ContentModel') };

#########################

my $cmstr = [ '(a)', '(a?)', '(a+)', '(a*)',
	      '(a,b,c,d)', '(a?,b?,c?,d?)',
	      '(a|b|c|d)', '(a|b|c|d)*', '(a|b|c|d)+', '(#PCDATA|a|b|c)*',
	      '(a,b?,(c|d))',
	      '(a,b?,(c|d)+,e*)',
	      '(a,b,((a,b)|(c|d))*)' ];

my ($cms, $cm, $str);
foreach $cms (@$cmstr) {
  $cm = XML::DTD::ContentModel->new($cms);
  ok(XML::DTD::ContentModel->isa($cm)) or
    diag("Error constructing XML::DTD::ContentModel from $cms\n");
  $str = $cm->string;
  ok($cms eq $str) or
    diag("XML::DTD::ContentModel for $cms has string value $str\n");
}
