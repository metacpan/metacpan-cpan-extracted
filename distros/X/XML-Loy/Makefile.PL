#!/usr/bin/env perl
use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'XML::Loy',
  AUTHOR       => 'Nils Diewald',
  ABSTRACT     => 'Extensible XML Reader and Writer',
  VERSION_FROM => 'lib/XML/Loy.pm',
  PREREQ_PM => {
    'Mojolicious' => '6.05',
    'Socket' => '1.97',
    'Time::Local' => '1.2',
    'Test::More' => 0,
    'Test::Warn' => '0.24',
    'Scalar::Util' => '1.63',
    'List::Util' => '1.63'
  },
  LICENSE     => 'perl',
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
    'meta-spec' => { version => 2 },
    requires  => { perl => '5.010001' },
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => {
        type => 'git',
        web => 'https://github.com/Akron/XML-Loy',
        url => 'https://github.com/Akron/XML-Loy.git',
      },
      bugtracker  => {
        web => 'https://github.com/Akron/XML-Loy/issues',
      },
    }
  }) : (),
  ),
  MIN_PERL_VERSION => '5.010001',
  test => {TESTS => 't/*.t t/Extensions/*.t t/Date/*.t' }
);
