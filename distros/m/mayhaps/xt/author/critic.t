#!perl

use strict;
use warnings;

use Test::Perl::Critic %{+{
  "-profile" => "xt/etc/perlcritic.rc",
}};
all_critic_ok();
