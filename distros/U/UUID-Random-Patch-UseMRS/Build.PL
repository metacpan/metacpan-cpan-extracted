
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
  "dist_abstract" => "Make UUID::Random use Math::Random::Secure's rand()",
  "dist_author" => [
    "Steven Haryanto <stevenharyanto\@gmail.com>"
  ],
  "dist_name" => "UUID-Random-Patch-UseMRS",
  "dist_version" => "0.01",
  "license" => "perl",
  "module_name" => "UUID::Random::Patch::UseMRS",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Math::Random::Secure" => 0,
    "UUID::Random" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
