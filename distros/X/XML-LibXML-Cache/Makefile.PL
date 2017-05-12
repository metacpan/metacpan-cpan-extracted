
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Document cache for XML::LibXML",
  "AUTHOR" => "Nick Wellnhofer <wellnhofer\@aevum.de>",
  "BUILD_REQUIRES" => {
    "File::Touch" => 0,
    "Test::Deep" => 0,
    "XML::LibXSLT" => "1.59"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "XML-LibXML-Cache",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "XML::LibXML::Cache",
  "PREREQ_PM" => {
    "URI" => 0,
    "XML::LibXML" => "1.59"
  },
  "VERSION" => "0.12",
  "test" => {
    "TESTS" => "t/*.t"
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



