
use strict;
use warnings;

use Module::Build 0.3601;
use lib qw{inc}; use PkgConfBuild;

my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Devel::CheckLib" => "1.01",
    "ExtUtils::PkgConfig" => "1.14",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Create a full-screen window with Xlib",
  "dist_author" => [
    "Stephen Nelson <stephenenelson\@mac.com>"
  ],
  "dist_name" => "X11-FullScreen",
  "dist_version" => "0.994",
  "license" => "perl",
  "module_name" => "X11::FullScreen",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "FindBin" => 0,
    "XSLoader" => 0,
    "lib" => 0,
    "perl" => "v5.10.0",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/show_image"
  ],
  "test_requires" => {
    "Test::Kwalitee" => 0,
    "Test::More" => 0
  }
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  my $tr = delete $module_build_args{test_requires};
  my $br = $module_build_args{build_requires};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

my $build = PkgConfBuild->new(%module_build_args);

$build->create_build_script;
