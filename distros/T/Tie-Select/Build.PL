use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
  module_name       => 'Tie::Select',
  dist_version_from => 'lib/Tie/Select.pm',
  dist_abstract     => 'Provides a localized interface to the select function',
  dist_author       => 'Joel Berger <joel.a.berger@gmail.com>',
  license           => 'perl',
  requires          => {
    'perl' => '5.6.2',
  },
  configure_requires => {
    'Module::Build' => 0.38,
  },
  meta_merge => {
    resources  => {
      repository => "http://github.com/jberger/Tie-Select",
    },
    no_index => {
      file => [ 'README.pod' ],
    },
  },
);

$builder->create_build_script;
