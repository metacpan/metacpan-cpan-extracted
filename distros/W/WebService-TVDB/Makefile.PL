
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Interface to http://thetvdb.com/",
  "AUTHOR" => "Andrew Jones <andrew\@arjones.co.uk>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "WebService-TVDB",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "WebService::TVDB",
  "PREREQ_PM" => {
    "Archive::Zip" => 0,
    "Carp" => 0,
    "Exporter" => 0,
    "File::Basename" => 0,
    "File::HomeDir" => 0,
    "File::Path" => 0,
    "LWP::Simple" => 0,
    "Object::Tiny" => 0,
    "URI::Escape" => 0,
    "XML::Simple" => 0,
    "constant" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "FindBin" => 0,
    "HTTP::Online" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Net::Ping" => "2.33",
    "Test::Exception" => 0,
    "Test::More" => "0.88"
  },
  "VERSION" => "1.133200",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Archive::Zip" => 0,
  "Carp" => 0,
  "Exporter" => 0,
  "File::Basename" => 0,
  "File::HomeDir" => 0,
  "File::Path" => 0,
  "File::Spec" => 0,
  "FindBin" => 0,
  "HTTP::Online" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "LWP::Simple" => 0,
  "Net::Ping" => "2.33",
  "Object::Tiny" => 0,
  "Test::Exception" => 0,
  "Test::More" => "0.88",
  "URI::Escape" => 0,
  "XML::Simple" => 0,
  "constant" => 0,
  "strict" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



