#!perl

use strict;
use warnings;

use Test::Perl::Critic %{+{
  "-profile" => "t/etc/perlcritic.rc",
}};
all_critic_ok();
