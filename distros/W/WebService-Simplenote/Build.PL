
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Note-taking through simplenoteapp.com",
  "dist_author" => [
    "Ioan Rogers <ioanr\@cpan.org>",
    "Fletcher T. Penney <owner\@fletcherpenney.net>"
  ],
  "dist_name" => "WebService-Simplenote",
  "dist_version" => "0.2.1",
  "license" => "gpl",
  "module_name" => "WebService::Simplenote",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "DateTime" => 0,
    "HTTP::Cookies" => 0,
    "JSON" => 0,
    "LWP::UserAgent" => 0,
    "Log::Any" => 0,
    "MIME::Base64" => 0,
    "Method::Signatures" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "MooseX::Types::DateTime" => 0,
    "MooseX::Types::Path::Class" => 0,
    "Try::Tiny" => 0,
    "namespace::autoclean" => 0,
    "open" => 0,
    "perl" => "v5.10.0"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
