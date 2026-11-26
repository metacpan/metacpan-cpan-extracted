# vi:set ft=perl:
use strict;
use warnings;

return {
    NAME   => 'Text::EditDistance::DamerauLevenshtein',
    AUTHOR => q{Lukas Mai <l.mai@web.de>},

    MIN_PERL_VERSION => '5.12.0',
    CONFIGURE_REQUIRES => {},
    BUILD_REQUIRES => {},
    TEST_REQUIRES => {
        'Test2::V0' => 0,
    },
    PREREQ_PM => {
        'Exporter' => '5.57',
        'XSLoader' => 0,
        'warnings' => 0,
    },
    DEVELOP_REQUIRES => {
        'Pod::Markdown::Githubert' => 0,
        'Test::Pod'                => 1.22,
    },

    depend => {
        Makefile    => '$(VERSION_FROM)',
        '$(OBJECT)' => join(' ', glob '*.h'),
    },

    REPOSITORY => [ codeberg => 'mauke' ],
    LICENSE => 'agpl_3',
};
