
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
  "dist_abstract" => "xine movie player interface",
  "dist_author" => [
    "Stephen Nelson <stephenenelson\@mac.com>"
  ],
  "dist_name" => "Video-Xine",
  "dist_version" => "0.26",
  "license" => "perl",
  "module_name" => "Video::Xine",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "DateTime" => 0,
    "Exporter" => 0,
    "Getopt::Long" => 0,
    "Pod::Usage" => 0,
    "X11::FullScreen" => 0,
    "XSLoader" => 0,
    "base" => 0,
    "constant" => 0,
    "perl" => "v5.8.3",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/xine_length",
    "bin/xine_play"
  ],
  "test_requires" => {
    "FindBin" => 0,
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
