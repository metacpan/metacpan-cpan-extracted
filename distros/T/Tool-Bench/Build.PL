
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601",
    "Test::More" => "0.98",
    "Test::Most" => "0.25"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Tool Bench is a generic framework for running benchmarks.",
  "dist_author" => [
    "Ben Hengst <notbenh\@cpan.org>"
  ],
  "dist_name" => "Tool-Bench",
  "dist_version" => "0.003",
  "license" => "perl",
  "module_name" => "Tool::Bench",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "JSON" => "2.53",
    "List::Util" => "1.25",
    "Mouse" => "1.02",
    "Time::HiRes" => "1.9725"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
