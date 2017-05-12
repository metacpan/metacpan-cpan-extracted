use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'WebService::Pandora',
               VERSION_FROM => 'lib/WebService/Pandora.pm',
               ABSTRACT_FROM => 'lib/WebService/Pandora.pod',
               AUTHOR => ['Mitch McCracken <mrmccrac@gmail.com>'],
               PREREQ_PM => {'JSON' => 0,
                             'Crypt::ECB' => "2.15",
                             'Crypt::Blowfish' => 0,
                             'LWP::UserAgent' => 0,
                             'URI' => 0,
                             'HTTP::Request' => 0,
                             'Data::Dumper' => 0},
               BUILD_REQUIRES => {'Test::More' => 0},
               MIN_PERL_VERSION => '5.6.0',
               LICENSE => 'artistic_2' );
