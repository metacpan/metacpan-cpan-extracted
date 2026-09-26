#!perl

use strict;
use warnings;

use Test::Perl::Critic %{+{
  "-profile" => "perlcriticrc",
}};
all_critic_ok();
