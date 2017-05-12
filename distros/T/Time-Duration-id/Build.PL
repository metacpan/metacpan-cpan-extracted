
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
  "dist_abstract" => "Describe time duration in Indonesian",
  "dist_author" => [
    "Steven Haryanto <stevenharyanto\@gmail.com>"
  ],
  "dist_name" => "Time-Duration-id",
  "dist_version" => "0.04",
  "license" => "perl",
  "module_name" => "Time::Duration::id",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Time::Duration" => "1.1",
    "perl" => "5.010001"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
