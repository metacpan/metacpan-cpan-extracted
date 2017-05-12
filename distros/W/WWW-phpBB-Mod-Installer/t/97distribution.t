use strict;
use warnings;
use Test::More;
plan( skip_all => 'skipping developer tests' ) unless -d ".svn";
eval {
    require Test::Distribution;
    Test::Distribution->import();
};
plan( skip_all => 'Test::Distribution not installed; skipping' ) if $@;
