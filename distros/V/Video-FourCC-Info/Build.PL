#!/usr/bin/perl

# Build.PL
#  Script to build and install this distribution
#
# $Id: Build.PL 10583 2009-12-22 02:37:49Z FREQUENCY@cpan.org $

use strict;
use warnings;

use lib 'inc';
use My::Builder;

my $builder = My::Builder->new(
  module_name           => 'Video::FourCC::Info',
  license               => 'unrestricted',
  dist_author           => 'Jonathan Yu <frequency@cpan.org>',
  dist_version_from     => 'lib/Video/FourCC/Info.pm',
  dynamic_config        => 0,
  create_readme         => 0,
  recursive_test_files  => 1,
  sign                  => 1,
  create_packlist       => 1,

  requires => {
    'perl'                    => 5.006,

    # Database related modules
    'DBI'                     => 0,
    'DBD::SQLite'             => 1.20,
  },
  build_requires => {
    # User tests for good functionality
    'Test::More'              => 0.62,
    'Test::NoWarnings'        => 0.084,

    # Database related modules
    'DBI'                     => 0,
    'DBD::SQLite'             => 1.20,
  },
  recommends => {
    # Video::Info for detecting FourCC used in files
    # CPAN.pm cannot install Video::Info for some reason (due to a quirky
    # distribution?), so we have to install Video::Info::Magic
    'Video::Info::Magic'      => 1.01,

    # Optional module DateTime
    'DateTime'                => 0,
  },
  conflicts => {
  },

  add_to_cleanup => [ 'Video-FourCC-Info-*' ],

  meta_merge => {
    resources => {
      # Custom resources (must begin with an uppercase letter)
      Ratings      => 'http://cpanratings.perl.org/d/Video-FourCC-Info',

      # Official keys (homepage, license, bugtracker)
      repository   => 'http://svn.ali.as/cpan/trunk/Video-FourCC-Info',
      bugtracker   => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Video-FourCC-Info',
      license      => 'http://edwardsamuels.com/copyright/beyond/articles/public.html',
    },
  },
);

$builder->add_build_element('dat'); # Make sure codecs.dat is copied
$builder->create_build_script();
