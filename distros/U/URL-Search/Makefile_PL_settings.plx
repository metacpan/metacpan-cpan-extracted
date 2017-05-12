use strict;
use warnings;

return {
    NAME   => 'URL::Search',
    AUTHOR => q{Lukas Mai <l.mai@web.de>},

    MIN_PERL_VERSION => '5.10.0',
    CONFIGURE_REQUIRES => {},
    BUILD_REQUIRES => {},
    TEST_REQUIRES => {
        'utf8'       => 0,
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'strict'   => 0,
        'warnings' => 0,
        'Exporter' => 5.57,
    },
    DEVELOP_REQUIRES => {
        'Test::Pod' => 1.22,
    },

    bonus => { github => 'mauke' },
};
