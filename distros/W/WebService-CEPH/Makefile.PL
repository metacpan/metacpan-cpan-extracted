
use strict;
use warnings;

use 5.014000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "CEPH Client for simple workflow",
  "AUTHOR" => "Victor Efimov <efimov\@reg.ru>, Aleksandr Babenko <babenko\@reg.ru>",
  "BUILD_REQUIRES" => {
    "Module::Build" => "0.3601"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "WebService-CEPH",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "WebService::CEPH",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Digest::MD5" => 0,
    "Fcntl" => 0,
    "File::Copy" => 0,
    "File::Path" => "2.07",
    "File::Slurp" => 0,
    "HTTP::Status" => 0,
    "Net::Amazon::S3" => "0.80",
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Temp" => 0,
    "HTTP::Daemon" => 0,
    "IO::Handle" => 0,
    "LWP::UserAgent" => 0,
    "POSIX" => 0,
    "Test::Deep" => 0,
    "Test::More" => 0,
    "Test::Spec" => 0
  },
  "VERSION" => "0.014",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Digest::MD5" => 0,
  "Fcntl" => 0,
  "File::Copy" => 0,
  "File::Path" => "2.07",
  "File::Slurp" => 0,
  "File::Temp" => 0,
  "HTTP::Daemon" => 0,
  "HTTP::Status" => 0,
  "IO::Handle" => 0,
  "LWP::UserAgent" => 0,
  "Module::Build" => "0.3601",
  "Net::Amazon::S3" => "0.80",
  "POSIX" => 0,
  "Test::Deep" => 0,
  "Test::More" => 0,
  "Test::Spec" => 0,
  "parent" => 0,
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



