#! perl

use strict;
use warnings;

exit 0 if $ENV{AUTOMATED_TESTING} && $] < 5.010001;

use ExtUtils::MakeMaker 7.54;

# For binaries/scripts.
my @bins; # = qw( prog );

my %makemaker =
  ( 'ExtUtils::MakeMaker' => 7.54 );

my %prereq =
  ( 'Test::More'          => 0,
  );

my %w =
( NAME                => 'Text::Template::Tiny',
  AUTHOR              => 'Johan Vromans <jv@cpan.org>',
  VERSION_FROM        => 'lib/Text/Template/Tiny.pm',
  ABSTRACT_FROM       => 'lib/Text/Template/Tiny.pm',
  LICENSE             => 'perl_5',
  PL_FILES            => {},
  MIN_PERL_VERSION    => '5.010001',

  @bins == 0 ? () : (
    EXE_FILES         => [ map { "script/$_" } @bins ],
    PL_FILES          => {
			   'script/pp.PL' => [ map { "script/$_" } @bins ]
			 },
  ),

  PREREQ_PM => {
    %makemaker,
    %prereq,
  },

  CONFIGURE_REQUIRES => {
    %makemaker,
  },

#  BUILD_REQUIRES => {
#  },

  TEST_REQUIRES  => {
    %prereq,
  },

  META_MERGE => {
    'meta-spec'  => { version => 2 },
    resources    => {
      license    => [ "https://dev.perl.org/licenses/" ],
      homepage   => 'https://github.com/sciurius/perl-Text-Template-Tiny',
      repository => {
	url => 'git://github.com/sciurius/perl-Text-Template-Tiny.git',
	web => 'https://github.com/sciurius/perl-Text-Template-Tiny',
	type => 'git',
      },
      bugtracker => {
        web => "https://github.com/sciurius/perl-Text-Template-Tiny/issues",
        mailto => 'jv@cpan.org',
      },
    },
  },
);

WriteMakefile(%w);
