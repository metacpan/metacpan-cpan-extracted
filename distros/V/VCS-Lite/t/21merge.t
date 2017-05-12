#!/usr/bin/perl -w
use strict;

use Test::More tests => 5;
use VCS::Lite;

my $el1 = VCS::Lite->new('data/mariner.txt');

#01
isa_ok($el1,'VCS::Lite','Return from new, passed filespec');

my $el2 = VCS::Lite->new('data/marinerx.txt');
my $el3 = VCS::Lite->new('data/marinery.txt');

$el1->apply($el2);

#02
ok(!$el1->delta($el2), "Not different once applied");

my $el1a = $el1->original;

#03
ok($el1->delta($el1a), "but different from original");

#04
isa_ok($el1a,'VCS::Lite','Return from original');

$el1a->apply($el3);
$el1->apply($el1a, base => 'original');

my $merged = $el1->text;

#Uncomment for debugging
open MERGE,'>merge1.out';
print MERGE $merged;
close MERGE;

my $results = do { local (@ARGV, $/) = 'data/marinerxy.txt'; <> }; # slurp entire file

#05
is($merged, $results, 'Merge matches expected results');


