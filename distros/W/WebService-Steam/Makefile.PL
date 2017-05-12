use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile( ABSTRACT_FROM =>   'lib/WebService/Steam.pm',
                      AUTHOR =>   'James Raspas <jraspass@gmail.com>',
              BUILD_REQUIRES => { 'ExtUtils::MakeMaker'  => 0,
                                  'Test::Most'           => 0,
                                  'Test::LWP::UserAgent' => 0 },
                        dist => { 'COMPRESS'             => 'gzip -9f',
                                  'SUFFIX'               => 'gz' },
                     LICENSE =>   'perl',
            MIN_PERL_VERSION =>   5.01,
                        NAME =>   'WebService::Steam',
                   PREREQ_PM => { 'DateTime'              => 0,
                                  'IO::All::LWP'          => 0,
                                  'Moose'                 => 0,
                                  'XML::Bare'             => 0 },
                VERSION_FROM =>   'lib/WebService/Steam.pm' );