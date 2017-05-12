#! /usr/bin/env perl
#

use utf8;
use strict;
use warnings;
use Module::Build;
use File::Basename 'dirname';
use Cwd 'abs_path';
use Env;

my $build = Module::Build->new(
  configure_requires => {
    'Module::Build' => 0.42,
  },
  module_name   => 'Test::Mojo::Pg',
  dist_name     => 'Test-Mojo-Pg',
  dist_version  => '0.33',
  dist_author   => 'RICHE',
  dist_abstract => 'Tear down and bring up databases with Mojo::Pg',
  license       => 'perl',
  requires => {
    'Mojo::Base'     => 0,
    'Mojo::Pg'       => 0,
    'File::Basename' => 0,
  },
  meta_add => {
    resources => {
      homepage   => 'https://github.com/rpcme/Test-Mojo-Pg',
      repository => 'https://github.com/rpcme/Test-Mojo-Pg.git',
      bugtracker => 'https://github.com/rpcme/Test-Mojo-Pg/issues',
      IRC        => 'irc://irc.perl.org/#mojo',
    },
  },
);

$build->create_build_script();
