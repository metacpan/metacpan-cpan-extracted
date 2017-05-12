
use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Perl extension for creating a television station",
  "AUTHOR" => "Stephen Nelson <stephenenelson\@mac.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Video-PlaybackMachine",
  "EXE_FILES" => [
    "bin/create_schema.pl",
    "bin/import_csv.pl",
    "bin/playback_machine.pl",
    "bin/scan_directory.pl",
    "bin/show_conflicts.pl"
  ],
  "LICENSE" => "perl",
  "NAME" => "Video::PlaybackMachine",
  "PREREQ_PM" => {
    "AppConfig" => 0,
    "Carp" => 0,
    "DBIx::Class::Core" => 0,
    "DBIx::Class::Schema" => 0,
    "DateTime" => 0,
    "DateTime::Format::Strptime" => 0,
    "DateTime::TimeZone::UTC" => 0,
    "Exporter" => 0,
    "File::Basename" => 0,
    "File::Find::Rule" => 0,
    "File::Temp" => 0,
    "File::stat" => 0,
    "FindBin" => 0,
    "Getopt::Long" => 0,
    "IO::Dir" => 0,
    "Image::Imlib2" => 0,
    "List::MoreUtils" => 0,
    "Log::Log4perl" => 0,
    "Moo" => 0,
    "Moo::Role" => 0,
    "POE" => 0,
    "POE::Kernel" => 0,
    "POE::Session" => 0,
    "POSIX" => 0,
    "SQL::Translator" => "0.11016",
    "Text::CSV" => 0,
    "Time::Duration" => 0,
    "Types::Standard" => 0,
    "Video::Xine" => 0,
    "Video::Xine::Event" => 0,
    "Video::Xine::Stream" => 0,
    "Video::Xine::Util" => 0,
    "X11::FullScreen" => 0,
    "autodie" => 0,
    "base" => 0,
    "constant" => 0,
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Data::Dumper" => 0,
    "Test::MockObject" => 0,
    "Test::MockObject::Extends" => 0,
    "Test::More" => 0,
    "lib" => 0
  },
  "VERSION" => "0.09",
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



