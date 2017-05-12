
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Define Tickit widget structures",
  "dist_author" => [
    "Tom Molesworth <cpan\@entitymodel.com>"
  ],
  "dist_name" => "Tickit-Builder",
  "dist_version" => "0.001",
  "license" => "perl",
  "module_name" => "Tickit::Builder",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Data::Dump" => 0,
    "Module::Load" => 0,
    "Tickit" => "0.12"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
