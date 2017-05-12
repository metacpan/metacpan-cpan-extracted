
use strict;
use warnings;

use 5.014000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "command line pastebin",
  "AUTHOR" => "Mike Doherty <doherty\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Dancer::Test" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::DBIx::Class" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "WWW-Hashbang-Pastebin",
  "EXE_FILES" => [
    "bin/app.pl",
    "bin/pastebin"
  ],
  "LICENSE" => "perl",
  "NAME" => "WWW::Hashbang::Pastebin",
  "PREREQ_PM" => {
    "DBIx::Class::Core" => 0,
    "DBIx::Class::Schema" => 0,
    "Daemon::Control" => 0,
    "Dancer" => 0,
    "Dancer::Plugin::DBIC" => 0,
    "Dancer::Plugin::EscapeHTML" => 0,
    "DateTime" => 0,
    "DateTime::Format::MySQL" => 0,
    "DateTime::Format::SQLite" => 0,
    "Integer::Tiny" => 0,
    "Plack" => 0,
    "SQL::Translator" => "0.11006",
    "Starman" => 0,
    "Template" => 0,
    "Try::Tiny" => 0,
    "YAML" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.004",
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



