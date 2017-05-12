
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "test that files do not contain soft breakpoints",
  "AUTHOR" => "James FitzGibbon <jfitz\@cpan.org>, Apocalypse <APOCAL\@cpan.org>, Chisel <chisel\@chizography.net>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "Test::Exception" => 0,
    "Test::More" => "0.92",
    "Test::Tester" => "0.09",
    "Test::UseAllModules" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Test-NoBreakpoints",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Test::NoBreakpoints",
  "PREREQ_PM" => {
    "Exporter" => 0,
    "File::Find" => 0,
    "File::Spec" => 0,
    "Test::Builder" => 0,
    "strict" => 0,
    "vars" => 0
  },
  "VERSION" => "0.15",
  "test" => {
    "TESTS" => "t/*.t t/baz/*.t"
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



