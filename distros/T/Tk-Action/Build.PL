
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
  module_name   => 'Tk::Action',
  license       => 'perl',
  dist_abstract => "action\ abstraction\ for\ tk",
  dist_name     => "Tk\-Action",
  dist_author   => [
"Jerome\ Quelin",
  ],
  requires      => {
    "MooseX::Has::Sugar" => '0',
    "English" => '0',
    "ExtUtils::MakeMaker" => '0',
    "Test::More" => '0',
    "perl" => '5.010',
    "File::Find" => '0',
    "Tk::Sugar" => '0',
    "MooseX::SemiAffordanceAccessor" => '0',
    "Moose" => '0.92',
  },
  script_files => [ qw() ],
);

$build->create_build_script;
