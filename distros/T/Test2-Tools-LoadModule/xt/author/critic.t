package main;

use strict;
use warnings;

use File::Spec;

use Test2::Tools::LoadModule;

load_module_or_skip_all PPI => 1.215;

load_module_or_skip_all 'Test::Perl::Critic', undef, [
    -profile => File::Spec->catfile( qw{ xt author perlcriticrc } ) ];

all_critic_ok();

1;

# ex: set textwidth=72 :
