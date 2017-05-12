#-*- perl -*-
#-*- coding: utf-8 -*-

use strict;
use warnings;

package MY;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Unicode::Precis::Preparation',
    VERSION_FROM       => 'lib/Unicode/Precis/Preparation.pm',
    MIN_PERL_VERSION   => 5.006001,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.26',
        'Test::More'          => '0.45',
    },
    PREREQ_PM => {
        Exporter => '0',
        XSLoader => '0',
    },
    ABSTRACT_FROM => 'lib/Unicode/Precis/Preparation.pm',
    AUTHOR        => 'Hatuka*nezumi - IKEDA Soji <hatuka@nezumi.nu>',
    LICENSE       => 'perl',
    LIBS          => [''],
    DEFINE        => '',
    INC           => '-I.',
    OBJECT        => '$(O_FILES)',
    META_MERGE    => {
        resources => {
            license => 'http://dev.perl.org/licenses/',
            repository =>
                'https://github.com/hatukanezumi/Unicode-Precis-Preparation/',
        },
    },
);
