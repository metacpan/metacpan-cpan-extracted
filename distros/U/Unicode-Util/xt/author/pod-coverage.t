use strict;
use warnings;
use Test::More;

eval 'use Test::Pod::Coverage 1.00';
plan skip_all => 'Test::Pod::Coverage 1.00 not installed; skipping' if $@;

all_pod_coverage_ok({ trustme => [qw<
    byte_length
    code_length
    code_chop
    graph_length
    graph_chop
    graph_reverse
    grapheme_index
    grapheme_rindex
    grapheme_substr
    grapheme_split
>] });
