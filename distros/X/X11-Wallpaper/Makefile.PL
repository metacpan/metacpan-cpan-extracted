
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "set X11 wallpaper using best available helper program",
  "AUTHOR" => "Richard Harris <RJH\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::Exception" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "X11-Wallpaper",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "X11::Wallpaper",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Exporter" => 0,
    "File::Which" => 0,
    "IPC::System::Simple" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.1",
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



