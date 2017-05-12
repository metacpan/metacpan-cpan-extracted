
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "(DEPRECATED) Make Time::Duration support milliseconds",
  "dist_author" => [
    "Steven Haryanto <stevenharyanto\@gmail.com>"
  ],
  "dist_name" => "Time-Duration-Patch-Millisecond",
  "dist_version" => "0.03",
  "license" => "perl",
  "module_name" => "Time::Duration::Patch::Millisecond",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Module::Patch" => "0.12",
    "Time::Duration" => 0,
    "perl" => "5.010001"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
