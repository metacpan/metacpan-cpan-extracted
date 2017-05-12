
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "common request class for web frameworks",
  "AUTHOR" => "Jesse Luehrs <doy\@tozt.net>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Web-Request",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Web::Request",
  "PREREQ_PM" => {
    "Encode" => 0,
    "File::Spec::Unix" => 0,
    "HTTP::Body" => 0,
    "HTTP::Headers" => 0,
    "HTTP::Message::PSGI" => 0,
    "Module::Runtime" => 0,
    "Moose" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "Plack::Util" => 0,
    "Stream::Buffered" => 0,
    "URI" => 0,
    "URI::Escape" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Data::Dumper" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "FindBin" => 0,
    "HTTP::Request" => 0,
    "HTTP::Request::Common" => 0,
    "IO::String" => 0,
    "Plack::App::URLMap" => 0,
    "Plack::Test" => 0,
    "Test::More" => "0.88",
    "Try::Tiny" => 0,
    "utf8" => 0
  },
  "VERSION" => "0.11",
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



