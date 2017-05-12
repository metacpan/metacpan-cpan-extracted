use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
  module_name => 'unigreek',
  dist_abstract => 'convert from unigreek notation and back',
  license => 'perl',
  dist_author => [
    'Nicolas Franck <nicolas.franck@ugent.be>'
  ],
  build_requires => {
    'Test::Exception' => 0,
    'Test::More' => 0,
    'Unicode::Normalize' => 0,
    'FindBin' => 0
  },
  #configure_requires => { 'Module::Build' => 0.40 },
  requires => {
    'perl' => '5.10.1',
  },
  create_license => 1,
  dist_version_from   => 'lib/UniGreek.pm',
  create_makefile_pl => 'traditional',
  meta_merge => {
    resources => {
      repository => 'https://github.com/nicolasfranck/unigreek'
    }
  }
);

$build->create_build_script;
