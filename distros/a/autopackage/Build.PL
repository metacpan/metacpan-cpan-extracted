
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Basename" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Automatically set your package based on how your module was loaded.",
  "dist_author" => [
    "Darin McBride <dmcbride\@cpan.org>"
  ],
  "dist_name" => "autopackage",
  "dist_version" => "0.01",
  "license" => "perl",
  "module_name" => "autopackage",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "B::Hooks::Parser" => "0.08",
    "Carp" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
