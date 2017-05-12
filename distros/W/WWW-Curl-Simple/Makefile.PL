
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A Simpler interface to WWW::Curl",
  "AUTHOR" => "Andreas Marienborg <andremar\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "WWW-Curl-Simple",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "WWW::Curl::Simple",
  "PREREQ_PM" => {
    "Carp" => 0,
    "HTTP::Request" => 0,
    "HTTP::Response" => 0,
    "Moose" => 0,
    "Scalar::Util" => 0,
    "Time::HiRes" => "1.9705",
    "WWW::Curl::Easy" => 0,
    "WWW::Curl::Multi" => 0,
    "namespace::clean" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::Exception" => 0,
    "Test::More" => "0.96",
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.100191",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "File::Spec" => 0,
  "HTTP::Request" => 0,
  "HTTP::Response" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Moose" => 0,
  "Scalar::Util" => 0,
  "Test::Exception" => 0,
  "Test::More" => "0.96",
  "Time::HiRes" => "1.9705",
  "WWW::Curl::Easy" => 0,
  "WWW::Curl::Multi" => 0,
  "base" => 0,
  "namespace::clean" => 0,
  "strict" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



