#!/usr/bin/perl
require v5.26;
use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Tree::Multi',
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Multi-way tree in Pure Perl with an even or odd number of keys per node.',
  license       => 'perl',
  requires      =>
   {'Carp'                =>0,
    'Data::Dump'          =>0,
    'feature'             =>0,
    'Data::Table::Text'   =>20200101,
    'Test2::API'          =>0,
    'Test::Most'          =>0,
   },
  configure_requires => {'Module::Build' => 0.4224},
  meta_merge =>
   {resources =>
     {repository => 'https://github.com/philiprbrenan/TreeMulti',
      bugtracker => 'https://github.com/philiprbrenan/TreeMulti/issues'
     }
   },
  create_readme =>  0,
  perl          => '5.26.0',
 );

$b->create_build_script();
