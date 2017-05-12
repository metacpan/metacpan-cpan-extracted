use strict;
use warnings;

use lib 'inc';

use Module::Build;
use MyBuilder;

my $builder = MyBuilder->new(
  module_name       => 'WWW::ErnestMarples',
  license           => 'perl',
  dist_author       => 'Andy Armstrong <andy@hexten.net>',
  dist_version_from => 'lib/WWW/ErnestMarples.pm',
  requires          => {
    'HTML::Tiny'     => 0,
    'LWP::UserAgent' => 0,
    'Test::More'     => 0,
  },
  add_to_cleanup => ['WWW-ErnestMarples-*'],
);

$builder->create_build_script();
