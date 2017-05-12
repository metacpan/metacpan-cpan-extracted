use strict;
use warnings;

use Module::Build 0.3601;

my $builder = Module::Build->new(
  module_name => 'Tie::Array::CSV',
  dist_author => 'Joel Berger',
  license => 'perl',
  requires => {
    'perl' => 5.006001,
    'Tie::File' => 0,
    'Text::CSV' => 0,
    'Scalar::Util' => 0,
  },
  configure_requires => {
    'Module::Build' => 0.3601,
  },
  meta_merge => {
    resources  => {
      repository => "http://github.com/jberger/Tie-Array-CSV",
      bugtracker => "http://github.com/jberger/Tie-Array-CSV/issues",
    },
    no_index => {
      file => [ 'README.pod' ],
    },
  }
);

$builder->create_build_script;

