#<<<
use strict; use warnings;
#>>>

use Config                        qw( %Config );
use ExtUtils::MakeMaker::CPANfile qw( WriteMakefile );

if ( !$Config{ d_alarm } ) {
  die( "Fatal error: alarm(2) is not defined on this system.\n" );
}

my %WriteMakefileArgs = (
  NAME             => 'Time::Out',
  AUTHOR           => 'Sven Willenbuecher <sven.willenbuecher@gmx.de>',
  VERSION_FROM     => 'lib/Time/Out.pm',
  ABSTRACT_FROM    => 'lib/Time/Out.pod',
  LICENSE          => 'Perl_5',
  MIN_PERL_VERSION => '5.8.0',
  META_MERGE       => {
    'meta-spec' => { version => 2 },
    provides    => {
      'Time::Out' => {
        file    => 'lib/Time/Out.pm',
        version => '0.24',
      },
      'Time::Out::Exception' => {
        file    => 'lib/Time/Out/Exception.pm',
        version => '0.24',
      },
      'Time::Out::ParamConstraints' => {
        file    => 'lib/Time/Out/ParamConstraints.pm',
        version => '0.24',
      },
    },
    resources => {
      repository => {
        type => 'git',
        url  => 'git://github.com/XSven/Time-Out.git',
        web  => 'https://github.com/XSven/Time-Out',
      },
      bugtracker => {
        web => 'https://github.com/XSven/Time-Out/issues',
      },
    },
  },
  clean     => { FILES                => 'Time-Out-* cover_db' },
  dist      => { COMPRESS             => 'gzip -9f', SUFFIX => 'gz', },
  realclean => { FILES                => 'local' },
  test      => { RECURSIVE_TEST_FILES => 1 },
);

require './maint/AuthorExtensions.pl'
  unless ( $Config{ osname } =~ m/\A(?:freebsd|openbsd|solaris)\z/ or exists( $ENV{ MAKELEVEL } ) );

WriteMakefile( %WriteMakefileArgs );
