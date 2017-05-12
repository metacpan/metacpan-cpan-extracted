use lib 'inc';
use Devel::AssertOS qw[-MSWin32];

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
  "dist_abstract" => "locate .git root at compile time and use as lib path",
  "dist_author" => [
    "Victor Efimov <efimov\@reg.ru>"
  ],
  "dist_name" => "lib-gitroot",
  "dist_version" => "0.004",
  "license" => "perl",
  "module_name" => "lib::gitroot",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "File::Spec" => 0,
    "Modern::Perl" => 0,
    "lib" => 0,
    "perl" => "5.010000"
  },
  "script_files" => [],
  "test_requires" => {
    "Capture::Tiny" => 0,
    "File::Path" => 0,
    "File::Temp" => "0.16",
    "Test::Deep" => 0,
    "Test::More" => 0,
    "Test::Pod" => "1.22",
    "Test::Spec" => 0
  }
);


my %fallback_build_requires = (
  "Capture::Tiny" => 0,
  "File::Path" => 0,
  "File::Temp" => "0.16",
  "Module::Build" => "0.3601",
  "Test::Deep" => 0,
  "Test::More" => 0,
  "Test::Pod" => "1.22",
  "Test::Spec" => 0
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
