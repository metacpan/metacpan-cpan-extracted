
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => "0.96"
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "a client library for WWW::Hashbang::Pastebin websites",
  "dist_author" => [
    "Mike Doherty <doherty\@cpan.org>"
  ],
  "dist_name" => "WWW-Hashbang-Pastebin-Client",
  "dist_version" => "0.003",
  "license" => "perl",
  "module_name" => "WWW::Hashbang::Pastebin::Client",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Getopt::Long" => 0,
    "HTTP::Tiny" => 0,
    "Pod::Usage" => 0,
    "perl" => "v5.10.1",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/p"
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
