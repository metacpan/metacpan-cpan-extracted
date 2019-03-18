#!perl
use utf8;
use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 2;
use Text::Amuse::Preprocessor;

for (1,2) {
    my $input = qq{#title Test\n#lang en\n\n0\n\n"0"\n\n0};
    my $output = '';
    my $pp = Text::Amuse::Preprocessor->new(input => \$input,
                                            output => \$output,
                                            fix_links => 1,
                                            fix_typography => 1,
                                            fix_nbsp => 1,)->process;
    is $output, "#title Test\n#lang en\n\n0\n\n“0”\n\n0\n";
    diag Dumper($output);
}
