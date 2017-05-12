
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Easy, automatic, specification-based tests",
  "AUTHOR" => "Tom Moertel <tom\@moertel.com>",
  "BUILD_REQUIRES" => {
    "File::Temp" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Test-LectroTest",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Test::LectroTest",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Class::Struct" => 0,
    "Data::Dumper" => 0,
    "Exporter" => 0,
    "Filter::Util::Call" => 0,
    "POSIX" => 0,
    "Scalar::Util" => 0,
    "Test::Builder" => 0,
    "constant" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.5001",
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



