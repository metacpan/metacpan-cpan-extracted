
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Basic tabbed window support",
  "AUTHOR" => "Tom Molesworth <cpan\@entitymodel.com>",
  "BUILD_REQUIRES" => {
    "Test::Identity" => 0,
    "Test::More" => "0.88",
    "Test::Refcount" => 0,
    "Tickit::Test" => "0.43",
    "Tickit::Widget::Static" => 0,
    "Tickit::Widget::VBox" => 0,
    "Tickit::Window" => "0.57",
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Tickit-Widget-Tabbed",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.010",
  "NAME" => "Tickit::Widget::Tabbed",
  "PREREQ_PM" => {
    "List::Util" => "1.26",
    "Scalar::Util" => 0,
    "Tickit::ContainerWidget" => "0.44",
    "Tickit::Widget" => "0.36",
    "Tickit::Window" => "0.28",
    "parent" => 0,
  },
  "VERSION_FROM" => "lib/Tickit/Widget/Tabbed.pm",
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



