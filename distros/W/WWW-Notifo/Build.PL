use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
  module_name       => 'WWW::Notifo',
  dist_author       => 'Andy Armstrong <andy@hexten.net>',
  dist_version_from => 'lib/WWW/Notifo.pm',
  requires          => {
    'Config::Tiny'   => 0,
    'Getopt::Long'   => 0,
    'JSON'           => '2.00',
    'LWP::UserAgent' => '5.815',
    'MIME::Base64'   => 0,
    'Test::More'     => 0,
    'accessors::ro'  => 0,
  },
  PL_files       => {},
  add_to_cleanup => ['WWW-Notifo-*'],
  sign           => 1,
  license        => 'perl',
  create_readme  => 1,
);

$build->create_build_script;
