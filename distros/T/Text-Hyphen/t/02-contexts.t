#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

use Text::Hyphen;
my $hyp = new Text::Hyphen;

my $word = 'representation';

my @arr1 = $hyp->hyphenate($word);
my @arr2 = $hyp->hyphenate($word, '-');

is_deeply(\@arr1, [qw/rep re sen ta tion/], 'list context');
is_deeply(\@arr2, ['rep-re-sen-ta-tion'], 'list context with implicit delimiter');

my $str;
open my $fh, '>', \$str;
print $fh $hyp->hyphenate($word);
close $fh;

# no dashes because is is a print of list of parts
is($str, $word, 'print');

$str = '';
open $fh, '>', \$str;
print $fh $hyp->hyphenate($word, 0);
close $fh;

# also test for falsy delimiter
is($str, 'rep0re0sen0ta0tion', 'print w/ delimiter which is falsy');

$str = '';
open $fh, '>', \$str;
print $fh map "($_)", $hyp->hyphenate('multiple');
close $fh;

is($str, '(mul)(ti)(ple)', '2nd example from synopsis');

done_testing;
