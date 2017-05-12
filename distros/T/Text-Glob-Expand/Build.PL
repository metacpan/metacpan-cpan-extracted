
use strict;
use warnings;

use Module::Build 0.2808;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.2808"
  },
  "configure_requires" => {
    "Module::Build" => "0.2808"
  },
  "dist_abstract" => "permute and expand glob-like text patterns",
  "dist_author" => [
    "Nick Stokoe <wulee\@cpan.org>"
  ],
  "dist_name" => "Text-Glob-Expand",
  "dist_version" => "1.1.1",
  "license" => "perl",
  "module_name" => "Text::Glob::Expand",
  "recommends" => {
    "Test::Perl::Critic" => "0.001000",
    "Test::Pod" => "1.14",
    "Test::Pod::Coverage" => "1.04"
  },
  "recursive_test_files" => 1,
  "requires" => {
    "Sub::Exporter" => 0,
    "Test::More" => 0,
    "version" => "0.77"
  },
  "script_files" => [],
  "test_requires" => {}
);


my %fallback_build_requires = (
  "Module::Build" => "0.2808"
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
