
# This file was automatically generated by Dist::Zilla::Plugin::ModuleBuild v6.024.
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
  "dist_abstract" => "Organize Data in Tables",
  "dist_author" => [
    "Shlomi Fish <shlomif\@cpan.org>"
  ],
  "dist_name" => "Text-Table",
  "dist_version" => "1.135",
  "license" => "open_source",
  "module_name" => "Text::Table",
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "List::Util" => 0,
    "Text::Aligner" => 0,
    "overload" => 0,
    "perl" => "5.008",
    "strict" => 0,
    "warnings" => 0
  },
  "test_requires" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => "0.88",
    "constant" => 0,
    "vars" => 0
  }
);


my %fallback_build_requires = (
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Module::Build" => "0.28",
  "Test::More" => "0.88",
  "constant" => 0,
  "vars" => 0
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);


$build->create_build_script;
