#!/usr/bin/env perl

BEGIN
  {
  unless ($ENV{AUTHOR_TESTING})
    {
    require Test::More;
    Test::More::plan(skip_all => 'this test is run only during development');
    }
  }

use strict;
use warnings;

use Test::Perl::Critic;

Test::Perl::Critic->import(-profile=>'perlcritic.rc') if (-f 'perlcritic.rc');

all_critic_ok();
