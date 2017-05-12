
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
  "dist_abstract" => "CEPH Client for simple workflow",
  "dist_author" => [
    "Victor Efimov <efimov\@reg.ru>",
    "Aleksandr Babenko <babenko\@reg.ru>"
  ],
  "dist_name" => "WebService-CEPH",
  "dist_version" => "0.014",
  "license" => "perl",
  "module_name" => "WebService::CEPH",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Digest::MD5" => 0,
    "Fcntl" => 0,
    "File::Copy" => 0,
    "File::Path" => "2.07",
    "File::Slurp" => 0,
    "HTTP::Status" => 0,
    "Net::Amazon::S3" => "0.80",
    "parent" => 0,
    "perl" => "5.014000",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "File::Temp" => 0,
    "HTTP::Daemon" => 0,
    "IO::Handle" => 0,
    "LWP::UserAgent" => 0,
    "POSIX" => 0,
    "Test::Deep" => 0,
    "Test::More" => 0,
    "Test::Spec" => 0
  }
);


my %fallback_build_requires = (
  "File::Temp" => 0,
  "HTTP::Daemon" => 0,
  "IO::Handle" => 0,
  "LWP::UserAgent" => 0,
  "Module::Build" => "0.3601",
  "POSIX" => 0,
  "Test::Deep" => 0,
  "Test::More" => 0,
  "Test::Spec" => 0
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
