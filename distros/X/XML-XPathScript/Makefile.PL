# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.012.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "a Perl framework for XML stylesheets",
  "AUTHOR" => "Yanick Champoux <yanick\@cpan.org>, Dominique Quatravaux <domq\@cpan.org>, Matt Sergeant <matt\@sergeant.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "XML-XPathScript",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "XML::XPathScript",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Clone" => 0,
    "Data::Dumper" => 0,
    "Exporter" => 0,
    "File::Basename" => 0,
    "Readonly" => 0,
    "Scalar::Util" => 0,
    "Symbol" => 0,
    "XML::LibXML" => 0,
    "XML::Parser" => 0,
    "XML::XPath" => 0,
    "XML::XPath::Node" => 0,
    "XML::XPath::NodeSet" => 0,
    "XML::XPath::XMLParser" => 0,
    "base" => 0,
    "bytes" => 0,
    "constant" => 0,
    "overload" => 0,
    "strict" => 0,
    "utf8" => 0,
    "vars" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "IO::File" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test" => 0,
    "Test::More" => 0
  },
  "VERSION" => "2.00",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Clone" => 0,
  "Data::Dumper" => 0,
  "Exporter" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Basename" => 0,
  "File::Spec" => 0,
  "IO::File" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Readonly" => 0,
  "Scalar::Util" => 0,
  "Symbol" => 0,
  "Test" => 0,
  "Test::More" => 0,
  "XML::LibXML" => 0,
  "XML::Parser" => 0,
  "XML::XPath" => 0,
  "XML::XPath::Node" => 0,
  "XML::XPath::NodeSet" => 0,
  "XML::XPath::XMLParser" => 0,
  "base" => 0,
  "bytes" => 0,
  "constant" => 0,
  "overload" => 0,
  "strict" => 0,
  "utf8" => 0,
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
