
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A suit of XML tools with Antlers.",
  "AUTHOR" => "Chris Prather <chris\@prather.org>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Path::Class" => 0,
    "Test::Deep" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0,
    "Test::Simple" => "0.94",
    "Test::XML" => "0.00"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "XML-Toolkit",
  "EXE_FILES" => [
    "bin/xmltk"
  ],
  "LICENSE" => "perl",
  "NAME" => "XML::Toolkit",
  "PREREQ_PM" => {
    "Bread::Board" => 0,
    "Bread::Board::Container" => 0,
    "Devel::PackagePath" => "0.01",
    "Encode" => 0,
    "Moose" => "0.92",
    "Moose::Role" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "MooseX::Aliases" => 0,
    "MooseX::App::Cmd" => 0,
    "MooseX::App::Cmd::Command" => 0,
    "MooseX::Getopt::Dashes" => 0,
    "MooseX::MetaDescription" => "0.03",
    "MooseX::MetaDescription::Description" => 0,
    "MooseX::MetaDescription::Meta::Attribute" => 0,
    "MooseX::MetaDescription::Meta::Trait" => 0,
    "MooseX::NonMoose" => 0,
    "MooseX::Types::Path::Class" => "0.04",
    "Template" => "2.20",
    "XML::SAX" => "0.96",
    "XML::SAX::Base" => 0,
    "XML::SAX::Writer" => "0.50",
    "aliased" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.15",
  "test" => {
    "TESTS" => "t/*.t t/02.namespaces/*.t t/06.reuse/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



