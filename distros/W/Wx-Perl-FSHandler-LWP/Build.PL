#!/usr/bin/perl -w

use strict;

use Module::Build;

my $build = new Module::Build
    ( module_name => 'Wx::Perl::FSHandler::LWP',
      author      => 'Mattia Barbon <mbarbon@cpan.org>',
      license     => 'perl',
      requires    => { 'Wx'         => 0.13,
                       'LWP'        => 5.7,
                       'IO::Scalar' => 2,
                       'Test::More' => 0.48,
                       },
      create_makefile_pl => 'passthrough',
    );

$build->create_build_script;
