# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.032.
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "A toolkit to help encrypt and decrypt XML Digital Signatures.",
  "AUTHOR" => "Timothy Legge <timlegge\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "XML-Enc",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.010",
  "NAME" => "XML::Enc",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Crypt::AuthEnc::GCM" => "0.062",
    "Crypt::Mode::CBC" => 0,
    "Crypt::OpenSSL::X509" => 0,
    "Crypt::PK::RSA" => "0.081",
    "Crypt::PRNG" => 0,
    "MIME::Base64" => 0,
    "XML::LibXML" => 0,
    "feature" => 0,
    "strict" => 0,
    "vars" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Crypt::OpenSSL::Guess" => 0,
    "CryptX" => 0,
    "Exporter" => 0,
    "File::Slurper" => 0,
    "File::Which" => 0,
    "Import::Into" => 0,
    "Test::Lib" => 0,
    "Test::More" => 0,
    "XML::LibXML::XPathContext" => 0,
    "namespace::autoclean" => 0
  },
  "VERSION" => "0.15",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Crypt::AuthEnc::GCM" => "0.062",
  "Crypt::Mode::CBC" => 0,
  "Crypt::OpenSSL::Guess" => 0,
  "Crypt::OpenSSL::X509" => 0,
  "Crypt::PK::RSA" => "0.081",
  "Crypt::PRNG" => 0,
  "CryptX" => 0,
  "Exporter" => 0,
  "File::Slurper" => 0,
  "File::Which" => 0,
  "Import::Into" => 0,
  "MIME::Base64" => 0,
  "Test::Lib" => 0,
  "Test::More" => 0,
  "XML::LibXML" => 0,
  "XML::LibXML::XPathContext" => 0,
  "feature" => 0,
  "namespace::autoclean" => 0,
  "strict" => 0,
  "vars" => 0,
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
