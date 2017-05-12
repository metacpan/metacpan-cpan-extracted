
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
  "dist_abstract" => "Diffbot Perl API",
  "dist_author" => [
    "Cesare Gargano <garcer\@cpan.org>"
  ],
  "dist_name" => "Webservice-Diffbot",
  "dist_version" => "0.003",
  "license" => "perl",
  "module_name" => "Webservice::Diffbot",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "JSON" => 0,
    "LWP::UserAgent" => 0,
    "Moo" => 0,
    "namespace::clean" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "Capture::Tiny" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "File::Spec::Functions" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "List::Util" => 0,
    "Test::Fatal" => 0,
    "Test::InDistDir" => 0,
    "Test::More" => 0,
    "URI" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "strictures" => 0,
    "version" => 0,
    "warnings" => 0
  }
);


my %fallback_build_requires = (
  "Capture::Tiny" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "File::Spec::Functions" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "List::Util" => 0,
  "Module::Build" => "0.3601",
  "Test::Fatal" => 0,
  "Test::InDistDir" => 0,
  "Test::More" => 0,
  "URI" => 0,
  "perl" => "5.006",
  "strict" => 0,
  "strictures" => 0,
  "version" => 0,
  "warnings" => 0
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
