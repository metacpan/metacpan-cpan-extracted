use strict;
use warnings;

use lib 'inc';

use Module::Build;
use MyBuilder;

my $builder = MyBuilder->new(
  module_name       => 'like',
  license           => 'perl',
  dist_author       => 'Andy Armstrong <andy@hexten.net>',
  dist_version_from => 'lib/like.pm',
  requires          => {
    'Test::More' => 0,
    'latest'     => '0.02',
  },
  add_to_cleanup => ['like-*'],
);

$builder->create_build_script();
