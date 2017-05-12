
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601",
    "Test::Exception" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Apply source filter on external module",
  "dist_author" => [
    "Yasutaka ATARASHI <yakex\@cpan.org>"
  ],
  "dist_name" => "filtered",
  "dist_version" => "v0.0.7",
  "license" => "perl",
  "module_name" => "filtered",
  "recommends" => {
    "Filter::tee" => 0,
    "PPI" => 0
  },
  "recursive_test_files" => 1,
  "requires" => {
    "perl" => "5.006"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
