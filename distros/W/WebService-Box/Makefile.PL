
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "manage your documents on Box.com",
  "AUTHOR" => "Renee Baecker <reneeb\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "WebService-Box",
  "EXE_FILES" => [],
  "LICENSE" => "artistic_2",
  "NAME" => "WebService::Box",
  "PREREQ_PM" => {
    "Carp" => 0,
    "DateTime" => "1.03",
    "HTTP::Tiny" => "0.034",
    "HTTP::Tiny::Multipart" => "0.02",
    "IO::Socket::SSL" => "1.953",
    "JSON" => "2.53",
    "Moo" => "1.003001",
    "OAuth2::Box" => "0.03",
    "Sub::Identify" => "0.04",
    "Sub::Name" => "0.05",
    "Test::Exception" => "0.32",
    "Test::Warn" => "0.24",
    "Type::Tiny" => "0.026"
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "0.02",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

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



