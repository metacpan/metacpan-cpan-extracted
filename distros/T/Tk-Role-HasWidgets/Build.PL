
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => "0.88"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "keep track of your tk widgets",
  "dist_author" => [
    "Jerome Quelin"
  ],
  "dist_name" => "Tk-Role-HasWidgets",
  "dist_version" => "1.112380",
  "license" => "perl",
  "module_name" => "Tk::Role::HasWidgets",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Moose::Role" => "0.92",
    "MooseX::Has::Sugar" => 0,
    "perl" => "5.010",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
