#!/usr/bin/perl -w
use strict;

use Test::More tests => 4;
use VCS::Lite;

my $el1 = VCS::Lite->new('data/mariner.txt');

#01
isa_ok($el1,'VCS::Lite','Return from new, passed filespec');

my $el2 = VCS::Lite->new('data/marinerx.txt');
my $el3 = VCS::Lite->new('data/marinery.txt');

my $el4 = $el1->merge($el2,$el3);

#02
isa_ok($el4,'VCS::Lite','Return from merge method');

my $merged = $el4->text;

#Uncomment for debugging
#open MERGE,'>merge1.out';
#print MERGE $merged;
#close MERGE;

my $results = do { local (@ARGV, $/) = 'data/marinerxy.txt'; <> }; # slurp entire file

#03
is($merged, $results, 'Merge matches expected results');

$el3 = VCS::Lite->new('data/marinerz.txt');

$el4 = $el1->merge($el2,$el3);
$merged = $el4->text;

#04
isa_ok($el4,'VCS::Lite','merge returns');

#Uncomment for debugging
#open MERGE,'>merge2.out';
#print MERGE $merged;
#close MERGE;

