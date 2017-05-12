#!/usr/bin/perl

# Build.PL
#  Script to build and install this distribution
#
# $Id: Build.PL 10608 2009-12-23 16:06:17Z FREQUENCY@cpan.org $

use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
  module_name           => 'WebService::UWO::Directory::Student',
  license               => 'unrestricted',
  dist_author           => 'Jonathan Yu <jawnsy@cpan.org>',
  dist_version_from     => 'lib/WebService/UWO/Directory/Student.pm',
  dynamic_config        => 0,
  create_readme         => 0,
  recursive_test_files  => 1,
  sign                  => 1,
  create_packlist       => 1,

  requires => {
    'perl'              => 5.006,

    # For retrieving & decoding HTML data
    'LWP::UserAgent'    => 0,
    'HTML::Entities'    => 0,

    # The tests are based on Test::More
    'Test::More'        => 0.62,
  },
  build_requires => {
    # User tests for good functionality
    'Test::NoWarnings'        => 0.084,
  },
  recommends => {
  },
  conflicts => {
  },

  add_to_cleanup => [ 'WebService-UWO-Directory-Student-*' ],
  script_files => [],

  meta_merge => {
    resources => {
      # Custom resources (must begin with an uppercase letter)
      Ratings      => 'http://cpanratings.perl.org/d/WebService-UWO-Directory-Student',

      # Official keys (homepage, license, bugtracker)
      repository   => 'http://svn.ali.as/cpan/trunk/WebService-UWO-Directory-Student',
      bugtracker   => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-UWO-Directory-Student',
      license      => 'http://edwardsamuels.com/copyright/beyond/articles/public.html',
    },
  },
);

$builder->create_build_script();
