
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::Harness" => 0,
    "Test::More" => "0.88"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Tests files for their content based on their file extension",
  "dist_author" => [
    "Moritz Onken"
  ],
  "dist_name" => "Test-File-Content",
  "dist_version" => "1.0.2",
  "license" => "bsd",
  "module_name" => "Test::File::Content",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Exporter" => 0,
    "File::Find" => 0,
    "Path::Class::File" => "0.23",
    "Test::Harness" => "3.22",
    "Test::More" => "0.96",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
