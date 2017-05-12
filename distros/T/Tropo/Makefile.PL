
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Use the TropoAPI via Perl",
  "AUTHOR" => "Renee Baecker <module\@renee-baecker.de>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Tropo",
  "EXE_FILES" => [],
  "LICENSE" => "artistic_2",
  "NAME" => "Tropo",
  "PREREQ_PM" => {
    "Class::Method::Modifiers" => 0,
    "HTTP::Tiny" => 0,
    "IO::Socket::SSL" => "1.56",
    "JSON" => "2.53",
    "Moo" => "1.003001",
    "Net::SSLeay" => "1.49",
    "Path::Tiny" => 0,
    "Type::Tiny" => "0.008",
    "URI" => 0,
    "URI::Escape" => 0,
    "XML::Simple" => 0
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "0.16",
  "test" => {
    "TESTS" => "t/restapi/*.t t/webapi/*.t"
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



