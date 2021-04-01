#!/usr/bin/perl
require v5.26;
use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Trim',
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Trim various things by removing leading and trailing whitespace.',
  license       => 'perl',
  requires      =>
   {'Carp'                =>0,
    'feature'             =>0,
    'Test2::API'          =>0,
    'Test::More'          =>0,
   },
  configure_requires => {'Module::Build' => 0.4224},
  meta_merge =>
   {resources =>
     {repository => 'https://github.com/philiprbrenan/Trim',
      bugtracker => 'https://github.com/philiprbrenan/Trim/issues'
     }
   },
  create_readme =>  0,
  perl          => '5.26.0',
 );

$b->create_build_script();
