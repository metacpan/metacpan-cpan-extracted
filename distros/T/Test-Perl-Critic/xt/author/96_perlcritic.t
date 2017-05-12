
use strict;
use warnings;

use English qw< -no_match_vars >;

use File::Spec;

my $rcfile;
BEGIN {
    $rcfile = File::Spec->catfile( qw< xt author perlcriticrc > );
}

use Test::Perl::Critic -profile => $rcfile;
all_critic_ok();
