#!perl

use strict;
use warnings;
use Module::Build;
use File::Spec;

# Copyright (C) 2010 Tim Jenness.
# All Rights Reserved.

# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself

my $file = File::Spec->catfile(File::Spec->curdir, "lib", "Tk",
			       "TextANSIColor.pm");

# Set it up.
my $build = Module::Build->new
  (
   module_name => 'Tk::TextANSIColor',
   abstract_from => $file,
   license  => 'perl',
   author => [
              'Tim Jenness <tjenness@cpan.org>',
             ],
   dist_version => 0.16,
   meta_merge => {
               resources =>  {
                              repository => "git://github.com/timj/perl-Tk-TextANSIColor.git",
                             },
                },
   requires => {
                'File::Spec' => 0.8,
                'Tk' => 804.0,
                'Term::ANSIColor' => 1.00,
               },
   build_requires => {
                      'Test::More' => 0,
                     },
  );

$build->create_build_script;
