
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Interact with a Mirth Connect server via REST",
  "AUTHOR" => "Tommy Stanton <tommystanton\@gmail.com>",
  "BUILD_REQUIRES" => {
    "Class::Monkey" => 0,
    "File::Temp" => 0,
    "HTTP::Daemon::SSL" => 0,
    "HTTP::Request::Params" => 0,
    "Path::Class" => "0.26",
    "Test::Deep" => 0,
    "Test::Fake::HTTPD" => "0.06",
    "Test::Fatal" => 0,
    "Test::File" => 0,
    "Test::More" => 0,
    "Test::XML" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "WebService-Mirth",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "WebService::Mirth",
  "PREREQ_PM" => {
    "IO::Socket::SSL" => "1.75",
    "Log::Minimal" => "0.13",
    "Mojolicious" => "1.97",
    "Moose" => "1.00",
    "Moose::Util::TypeConstraints" => 0,
    "MooseX::Params::Validate" => 0,
    "MooseX::Types::Path::Class::MoreCoercions" => "0.002",
    "aliased" => 0,
    "namespace::autoclean" => 0
  },
  "VERSION" => "0.131220",
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



