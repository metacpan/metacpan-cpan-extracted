
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Dancer::Test" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::DBIx::Class" => 0,
    "Test::More" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "command line pastebin",
  "dist_author" => [
    "Mike Doherty <doherty\@cpan.org>"
  ],
  "dist_name" => "WWW-Hashbang-Pastebin",
  "dist_version" => "0.004",
  "license" => "perl",
  "module_name" => "WWW::Hashbang::Pastebin",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "DBIx::Class::Core" => 0,
    "DBIx::Class::Schema" => 0,
    "Daemon::Control" => 0,
    "Dancer" => 0,
    "Dancer::Plugin::DBIC" => 0,
    "Dancer::Plugin::EscapeHTML" => 0,
    "DateTime" => 0,
    "DateTime::Format::MySQL" => 0,
    "DateTime::Format::SQLite" => 0,
    "Integer::Tiny" => 0,
    "Plack" => 0,
    "SQL::Translator" => "0.11006",
    "Starman" => 0,
    "Template" => 0,
    "Try::Tiny" => 0,
    "YAML" => 0,
    "base" => 0,
    "perl" => "5.014000",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/app.pl",
    "bin/pastebin"
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
