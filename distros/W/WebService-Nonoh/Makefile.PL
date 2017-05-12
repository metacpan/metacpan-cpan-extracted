
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "make nonoh calls from Perl",
  "AUTHOR" => "Ailin Nemui <ailin at devio dot us>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "WebService-Nonoh",
  "EXE_FILES" => [
    "bin/nonoh"
  ],
  "LICENSE" => "perl",
  "NAME" => "WebService::Nonoh",
  "PREREQ_PM" => {
    "CGI" => 0,
    "Crypt::CBC" => 0,
    "Crypt::Rijndael" => 0,
    "HTML::Parser" => 0,
    "Hash::Util" => 0,
    "JSON::PP" => 0,
    "LWP::ConnCache" => 0,
    "MIME::Base64" => 0,
    "Moops" => 0,
    "Text::Balanced" => 0,
    "WWW::Mechanize" => 0,
    "XML::LibXML" => 0,
    "constant" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => 0,
    "Test::Most" => 0,
    "ok" => 0,
    "strict" => 0
  },
  "VERSION" => "0.1",
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



