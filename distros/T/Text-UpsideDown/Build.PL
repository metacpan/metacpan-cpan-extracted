
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Flip text upside-down using Unicode",
  "dist_author" => [
    "Mike Doherty <doherty\@cpan.org>",
    "Marcel Gr\303\274nauer <marcel\@cpan.org>"
  ],
  "dist_name" => "Text-UpsideDown",
  "dist_version" => "1.22",
  "license" => "perl",
  "module_name" => "Text::UpsideDown",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Exporter" => 0,
    "Getopt::Long" => 0,
    "Pod::Usage" => 0,
    "charnames" => 0,
    "open" => 0,
    "perl" => "5.008",
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/ud"
  ],
  "test_requires" => {
    "Capture::Tiny" => 0,
    "File::Spec" => 0,
    "IPC::Run3" => 0,
    "Test::More" => "0.88",
    "Test::Script" => "1.05"
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

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
