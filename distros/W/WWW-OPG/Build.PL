#!/usr/bin/perl

# Build.PL
#  Script to build and install this distribution
#
# $Id: Build.PL 10704 2010-01-01 01:28:37Z FREQUENCY@cpan.org $

use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
  module_name           => 'WWW::OPG',
  license               => 'unrestricted',
  dist_author           => 'Jonathan Yu <jawnsy@cpan.org>',
  dist_version_from     => 'lib/WWW/OPG.pm',
  dynamic_config        => 0,
  create_readme         => 0,
  recursive_test_files  => 1,
  sign                  => 1,
  create_packlist       => 1,

  requires => {
    'perl'              => 5.006,
    'LWP::UserAgent'    => 0,

    # The tests are based on Test::More
    'Test::More'        => 0.62,
    'DateTime'          => 0.4305,
  },
  build_requires => {
    # User tests for good functionality
    'Test::NoWarnings'        => 0.084,
  },
  recommends => {
  },
  conflicts => {
  },

  add_to_cleanup => [ 'WWW-OPG-*' ],
  script_files => [],

  meta_merge => {
    resources => {
      # Custom resources (must begin with an uppercase letter)
      Ratings      => 'http://cpanratings.perl.org/d/WWW-OPG',

      # Official keys (homepage, license, bugtracker)
      repository   => 'http://svn.ali.as/cpan/trunk/WWW-OPG',
      bugtracker   => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-OPG',
      license      => 'http://edwardsamuels.com/copyright/beyond/articles/public.html',
    },
  },
);

$builder->create_build_script();
