
# This file was automatically generated by Dist::Zilla::Plugin::ModuleBuild v6.025.
use strict;
use warnings;

use Module::Build 0.28;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.28"
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => 0,
    "Module::Build" => "0.28"
  },
  "dist_abstract" => "check that all your files are tidy.",
  "dist_author" => [
    "Shlomi Fish <shlomif\@cpan.org>"
  ],
  "dist_name" => "Test-PerlTidy",
  "dist_version" => 20230226,
  "license" => "perl",
  "module_name" => "Test::PerlTidy",
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "English" => 0,
    "Exporter" => 0,
    "File::Spec" => 0,
    "IO::File" => 0,
    "Path::Tiny" => "0.100",
    "Perl::Tidy" => 20220613,
    "Test::Builder" => 0,
    "Text::Diff" => 0,
    "parent" => 0,
    "perl" => "5.014",
    "strict" => 0,
    "vars" => 0,
    "warnings" => 0
  },
  "test_requires" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => "0.88"
  }
);


my %fallback_build_requires = (
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Module::Build" => "0.28",
  "Test::More" => "0.88"
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);


$build->create_build_script;
