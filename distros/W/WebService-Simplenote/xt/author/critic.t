#!perl

use strict;
use warnings;

use Test::Perl::Critic (-profile => "xt/perlcriticrc") x!! -e "xt/perlcriticrc";
all_critic_ok();
