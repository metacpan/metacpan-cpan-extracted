use strict;
use warnings;
use Test::More;
plan( skip_all => 'skipping developer tests' ) unless -d ".svn";
eval { 
    require Test::Kwalitee;
    Test::Kwalitee->import( tests => [ qw( -has_meta_yml ) ] ) 
};
plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;
