#!/usr/bin/perl
require v5.26;
use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Text::Match',
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Match text question against possible answer strings',
  license       => 'perl',
  requires      =>
   {'Carp'                =>0,
    'Data::Dump'          =>0,
    'Math::Permute::List' =>0,
    'feature'             =>0,
    'Data::Table::Text'   =>20200101,
    'Test2::API'          =>0,
    'Test::More'          =>0,
   },
  configure_requires => {'Module::Build' => 0.4224},
  meta_merge =>
   {resources =>
     {repository => 'https://github.com/philiprbrenan/TextMatch',
      bugtracker => 'https://github.com/philiprbrenan/TextMatch/issues'
     }
   },
  create_readme =>  0,
  perl          => '5.26.0',
 );

$b->create_build_script();
