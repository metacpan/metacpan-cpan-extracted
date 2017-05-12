
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Perl interface to Notify My Android web API",
  "AUTHOR" => "Steve Huff <shuff\@cpan.org>, Chisel <chisel\@chizography.net>",
  "BUILD_REQUIRES" => {
    "Data::Dumper" => 0,
    "Test::More" => 0,
    "Test::UseAllModules" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "WebService-NotifyMyAndroid",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "WebService::NotifyMyAndroid",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Data::Printer" => 0,
    "FindBin::libs" => 0,
    "LWP::Protocol::https" => 0,
    "Params::Validate" => 0,
    "Readonly" => 0,
    "Regexp::Common" => 0,
    "WebService::Simple" => 0,
    "base" => 0,
    "strictures" => 1
  },
  "VERSION" => "0.0.6",
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



