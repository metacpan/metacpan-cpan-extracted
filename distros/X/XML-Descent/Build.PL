require 5.006001;

use strict;
use warnings;
use Module::Build;

use lib 'inc';

use MyBuilder;

my $builder = MyBuilder->new(
  module_name       => 'XML::Descent',
  sign              => 1,
  license           => 'perl',
  dist_author       => 'Andy Armstrong <andy@hexten.net>',
  dist_version_from => 'lib/XML/Descent.pm',
  requires          => {
    'Test::More'        => 0,
    'XML::TokeParser'   => 0,
    'Test::Differences' => 0,
  },
  add_to_cleanup => ['XML-Descent-*'],
);

$builder->create_build_script();
