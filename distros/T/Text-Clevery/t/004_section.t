#!perl -w

use strict;
use Test::More skip_all => 'not yet implemented';

use Text::Clevery;
use Text::Clevery::Parser;

my $tc = Text::Clevery->new(verbose => 2);

my @set = (
#TODO
);

for my $d(@set) {
    my($source, $vars, $expected, $msg) = @{$d};
    is eval { $tc->render_string($source, $vars) }, $expected, $msg
        or do { ($@ && diag $@); diag $source };
}

done_testing;
