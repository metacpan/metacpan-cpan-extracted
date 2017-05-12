
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Fast SNMP data poller daemon, with storage and graphing",
  "AUTHOR" => "Oliver Gorwits <oliver\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "YATG",
  "EXE_FILES" => [
    "bin/yatg-trim",
    "bin/yatg_updater"
  ],
  "LICENSE" => "perl",
  "NAME" => "YATG",
  "PREREQ_PM" => {
    "Class::Data::Inheritable" => 0,
    "DBI" => 0,
    "Data::Printer" => 0,
    "Exporter" => 0,
    "File::Basename" => 0,
    "File::Copy" => 0,
    "File::Spec::Functions" => 0,
    "File::Temp" => 0,
    "File::stat" => 0,
    "FindBin" => 0,
    "Lingua::EN::Inflect" => 0,
    "Log::Dispatch::Syslog" => 0,
    "Module::MultiConf" => "0.0301",
    "Net::Netmask" => 0,
    "POSIX" => 0,
    "Readonly" => 0,
    "Regexp::Common" => 0,
    "SNMP" => 0,
    "SNMP::Effective" => 0,
    "Scriptalicious" => 0,
    "Symbol" => 0,
    "Sys::Syslog" => "0.25",
    "Time::HiRes" => 0,
    "YAML::XS" => 0,
    "base" => 0,
    "strict" => 0,
    "vars" => 0,
    "warnings" => 0
  },
  "VERSION" => "5.20002",
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



