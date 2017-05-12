use strict;
use warnings;
use Module::Build;
use 5.005;

use lib 'inc';

use MyBuilder;

my $builder = MyBuilder->new(
  module_name       => 'URI::geo',
  license           => 'perl',
  dist_author       => 'Andy Armstrong <andy@hexten.net>',
  dist_version_from => 'lib/URI/geo.pm',
  requires          => {
    'Test::More' => 0,
    'URI'        => 0,
  },
  add_to_cleanup => ['URI-geo-*'],
);

$builder->create_build_script();
