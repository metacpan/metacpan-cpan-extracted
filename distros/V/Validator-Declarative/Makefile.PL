
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Declarative parameters validation",
  "AUTHOR" => "Oleg Kostyuk <cub\@cpan.org>",
  "BUILD_REQUIRES" => {
    "ClassOne" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "base" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Validator-Declarative",
  "EXE_FILES" => [],
  "LICENSE" => "bsd",
  "NAME" => "Validator::Declarative",
  "PREREQ_PM" => {
    "Data::Dumper" => 0,
    "Email::Valid" => 0,
    "Error" => 0,
    "Exporter" => 0,
    "Module::Load" => 0,
    "Readonly" => 0,
    "Scalar::Util" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.20130722.2105",
  "test" => {
    "TESTS" => "t/*.t t/converters/*.t t/parametrized-types/*.t t/simple-types/*.t"
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



