use strict;
use warnings;

use lib 'inc';

use Module::Build;
use MyBuilder;

my $builder = MyBuilder->new(
  module_name       => 'latest',
  license           => 'perl',
  dist_author       => 'Andy Armstrong <andy@hexten.net>',
  dist_version_from => 'lib/latest.pm',
  requires          => {
    'Test::More' => 0,
    'version'    => 0
  },
  add_to_cleanup => ['latest-*'],
);

$builder->create_build_script();
