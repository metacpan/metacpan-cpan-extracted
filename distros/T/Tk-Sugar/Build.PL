
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
  module_name   => 'Tk::Sugar',
  license       => 'perl',
  dist_abstract => "Sugar\ syntax\ for\ Tk",
  dist_name     => "Tk\-Sugar",
  dist_author   => [
"Jerome\ Quelin",
  ],
  requires      => {
    "perl" => '5.008',
    "Test::More" => '0',
    "English" => '0',
    "File::Find" => '0',
    "ExtUtils::MakeMaker" => '0',
    "Sub::Exporter" => '0',
  },
  script_files => [ qw() ],
);

$build->create_build_script;
