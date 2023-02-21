use strict;
use Test::More 0.98;
use utf8;

use Data::Dumper;
use Text::ANSI::Fold qw(ansi_fold);

my $default_prefix = '>>> ';

sub folded {
    my $opt = ref $_[0] ? +shift : {};
    my $prefix = $opt->{prefix} // $default_prefix;
    my($s, $w) = splice @_, 0, 2;
    $s = $prefix . $s;
    $w += length $prefix;
    my($folded, $rest) = ansi_fold($s, $w, @_, prefix => $prefix);
    $folded =~ s/^\Q$prefix\E//r;
}

$_ = "aaa/bbb/cccdddeeefff";
is(folded($_, 5, boundary => 'word'), "aaa/",      "boundary: word 5");
is(folded($_, 6, boundary => 'word'), "aaa/",      "boundary: word 6");
is(folded($_, 7, boundary => 'word'), "aaa/bbb",   "boundary: word 7");
is(folded($_, 9, boundary => 'word'), "aaa/bbb/c", "boundary: word 9");

configure Text::ANSI::Fold boundary => 'word';
is(folded($_, 5), "aaa/",      "config boundary: word 5");
is(folded($_, 6), "aaa/",      "config boundary: word 6");
is(folded($_, 7), "aaa/bbb",   "config boundary: word 7");
is(folded($_, 9), "aaa/bbb/c", "config boundary: word 9");

$_ = "000 000 000";
is(folded($_, 5, boundary => 'word'), "000 ",    "boundary: check 0");
is(folded($_, 6, boundary => 'word'), "000 ",    "boundary: check 0");
is(folded($_, 7, boundary => 'word'), "000 000", "boundary: check 0");

configure Text::ANSI::Fold width => 0, boundary => '';
$_ = "__________aaa bbb/ccc ddd";

done_testing;
