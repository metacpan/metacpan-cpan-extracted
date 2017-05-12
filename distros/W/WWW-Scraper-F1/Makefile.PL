
use strict;
use warnings;

use 5.014000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Scrape f1.com for next race en championship.",
  "AUTHOR" => "Freek Kalter <freek\@kalteronline.org>",
  "BUILD_REQUIRES" => {
    "FindBin" => 0,
    "Test::More" => 0,
    "URI::file" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "WWW-Scraper-F1",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "WWW::Scraper::F1",
  "PREREQ_PM" => {
    "DateTime::Format::Duration" => "1.03",
    "DateTime::Format::Natural" => "1.00",
    "Encode" => "2.47",
    "Exporter" => 0,
    "HTML::TreeBuilder" => "5.03",
    "LWP" => "6.04",
    "Storable" => "2.39",
    "Test::Pod" => 0,
    "Time::Piece" => "1.20",
    "charnames" => 0,
    "open" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.007",
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



