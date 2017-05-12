
use strict;
use warnings;

use Module::Build 0.38;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.38",
    "Test::More" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.38"
  },
  "dist_abstract" => "Provides access to the v3 Bukget API",
  "dist_author" => [
    "Ben van Staveren <madcat\@cpan.org>"
  ],
  "dist_name" => "WebService-Bukget",
  "dist_version" => "1.00",
  "license" => "perl",
  "module_name" => "WebService::Bukget",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Mojo::Base" => 0,
    "Mojo::JSON" => 0,
    "Mojo::UserAgent" => 0,
    "Try::Tiny" => 0,
    "boolean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
