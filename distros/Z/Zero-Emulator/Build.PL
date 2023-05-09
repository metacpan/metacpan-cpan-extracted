#!/usr/bin/perl
require v5.26;
use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Zero::Emulator',
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Assemble and execute code written in the Zero programming language.',
  license       => 'perl',
  requires      =>
   {'Carp'                =>0,
    'Data::Dump'          =>0,
    'feature'             =>0,
    'Data::Table::Text'   =>0,
    'Test2::API'          =>0,
    'Test::More'          =>0,
    'Test::Most'          =>0,
   },
  configure_requires => {'Module::Build' => 0.4224},
  meta_merge =>
   {resources =>
     {repository => 'https://github.com/philiprbrenan/zero',
      bugtracker => 'https://github.com/philiprbrenan/zero/issues'
     }
   },
  create_readme =>  0,
  perl          => '5.30.0',
 );

$b->create_build_script();
