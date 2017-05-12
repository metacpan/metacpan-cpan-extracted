
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
  "dist_abstract" => "Create an LWP UserAgent that records and plays back sessions",
  "dist_author" => [
    "Edward Allen <ealleniii\@cpan.org>"
  ],
  "dist_name" => "Test-LWP-Recorder",
  "dist_version" => "0.1.1",
  "license" => "perl",
  "module_name" => "Test::LWP::Recorder",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Digest::MD5" => 0,
    "File::Slurp" => 0,
    "File::Spec" => 0,
    "HTTP::Response" => 0,
    "HTTP::Status" => 0,
    "LWP::UserAgent" => 0,
    "List::Util" => 0,
    "base" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "LWPx::Record::DataSection" => 0,
    "Test::More" => "0.88",
    "lib" => 0
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
