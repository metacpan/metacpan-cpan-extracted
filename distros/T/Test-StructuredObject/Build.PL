
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "FindBin" => 0,
    "Module::Build" => "0.4003",
    "Test::More" => "0.98"
  },
  "configure_requires" => {
    "Module::Build" => "0.4003"
  },
  "dist_abstract" => "Use a structured execution-graph to create a test object which runs your tests smartly.",
  "dist_author" => [
    "Kent Fredric <kentnl\@cpan.org>"
  ],
  "dist_name" => "Test-StructuredObject",
  "dist_version" => "0.01000010",
  "license" => "perl",
  "module_name" => "Test::StructuredObject",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "B::Deparse" => 0,
    "Carp" => 0,
    "Moose" => 0,
    "Sub::Exporter" => 0,
    "Test::More" => "0.98",
    "namespace::autoclean" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
