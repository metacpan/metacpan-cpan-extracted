
use strict;
use warnings;

use 5.006000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A Hadoop Hive client using the Thrift API",
  "AUTHOR" => "Stephen R. Scaffidi <sscaffidi\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Thrift-API-HiveClient",
  "EXE_FILES" => [],
  "LICENSE" => "apache",
  "NAME" => "Thrift::API::HiveClient",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Class::Accessor" => 0,
    "Moo" => 0,
    "Thrift" => 0,
    "Thrift::BinaryProtocol" => 0,
    "Thrift::BufferedTransport" => 0,
    "Thrift::Socket" => 0,
    "Thrift::TException" => 0,
    "base" => 0,
    "constant" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.003",
  "test" => {
    "TESTS" => ""
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



