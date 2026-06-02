#! perl

use strict;
use warnings;

exit 0 if $ENV{AUTOMATED_TESTING} && $] < 5.036000;

use ExtUtils::MakeMaker 7.54;

# For binaries/scripts.
my @bins; # = qw( prog );

my %makemaker =
  ( 'ExtUtils::MakeMaker' => 7.54 );

my %prereq =
  ( 'Test::More'            => 0,
    'Object::Pad'           => 0.825,
    'Class::JSON_Object'    => 0.05,
    'LWP::UserAgent'        => 0,
    'HTTP::Request::Common' => 0,
    'JSON::PP'              => 0,
    'Data::Printer'         => 0,
    'List::Util'            => 0,
  );

my %w =
( NAME                => 'Weenect::API',
  AUTHOR              => 'Johan Vromans <jv@cpan.org>',
  VERSION_FROM        => 'lib/Weenect.pm',
  ABSTRACT            => 'API to Weenect tracker server',
  LICENSE             => 'perl_5',
  PL_FILES            => {},
  MIN_PERL_VERSION    => '5.036000',

  @bins == 0 ? () : (
    EXE_FILES         => [ map { "scripts/$_" } @bins ],
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
      homepage   => 'https://github.com/sciurius/perl-Weenect-API',
      repository => {
	url => 'git://github.com/sciurius/perl-Weenect-API.git',
	web => 'https://github.com/sciurius/perl-Weenect-API',
	type => 'git',
      },
      bugtracker => {
        web => 'https://github.com/sciurius/perl-Weenect-API/issues',
        mailto => 'jv@cpan.org',
      },
    },
  },
);

WriteMakefile(%w);
