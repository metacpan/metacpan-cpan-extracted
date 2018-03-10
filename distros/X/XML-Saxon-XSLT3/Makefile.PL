#!perl -w

require 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'XML::Saxon::XSLT3',
  VERSION_FROM => 'lib/XML/Saxon/XSLT3.pm',
  MIN_PERL_VERSION => '5.008',
  CONFIGURE_REQUIRES => {
    'Alien::Saxon' => '0',
  },
  BUILD_REQUIRES => {
    'Alien::Saxon' => '0',
  },
  TEST_REQUIRES => {
    'Alien::Saxon' => '0',
    'Test::More' => '0.88',
    'Inline::Java' => 0,
    'XML::LibXML' => '1.60',
  },
  PREREQ_PM => {
    'Alien::Saxon' => '0',
    'Inline::Java' => 0,
    'XML::LibXML' => 0,
  },
  clean => {FILES => "_Inline"},
  META_MERGE => {
    "meta-spec" => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'git://github.com/mohawk2/xml-saxon-xslt3',
        web => 'https://github.com/mohawk2/xml-saxon-xslt3',
      },
    },
  },
);
