use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Text::Table::Lite',
    VERSION_FROM     => 'lib/Text/Table/Lite.pm',
    ABSTRACT         => 'Unicode-aware terminal tables with multiline cells',
    AUTHOR           => 'H.Q. Wang',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.016',
    PREREQ_PM        => {
        'Unicode::GCString' => '2013.10',
        'Test::More'        => '0.96',
    },
    clean             => { FILES => 'Text-Table-Lite-*' },
);
