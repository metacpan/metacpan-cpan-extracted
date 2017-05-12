
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
  "dist_abstract" => "XML stylesheet system",
  "dist_author" => [
    "Yanick Champoux <yanick\@cpan.org>"
  ],
  "dist_name" => "XML-XSS",
  "dist_version" => "0.3.4",
  "license" => "perl",
  "module_name" => "XML::XSS",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Getopt::Long" => 0,
    "Moose" => 0,
    "Moose::Exporter" => 0,
    "Moose::Role" => 0,
    "MooseX::ClassAttribute" => 0,
    "MooseX::Clone" => 0,
    "MooseX::SemiAffordanceAccessor" => 0,
    "Perl::Tidy" => 0,
    "Scalar::Util" => 0,
    "XML::LibXML" => 0,
    "overload" => 0,
    "perl" => "v5.10.0",
    "warnings" => 0
  },
  "script_files" => [
    "bin/xss"
  ],
  "test_requires" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::Class" => 0,
    "Test::Class::Load" => 0,
    "Test::More" => "0.94",
    "base" => 0,
    "lib" => 0,
    "strict" => 0
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
