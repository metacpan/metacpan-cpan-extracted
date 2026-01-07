use 5.016;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'WWW::Crawl',
    VERSION      => '0.3',
    ABSTRACT     => 'Lightweight web crawler with optional JS rendering',
    AUTHOR       => 'Ian Boddison <bod@cpan.org>',
    LICENSE      => 'perl',

    MIN_PERL_VERSION => '5.016',

    PREREQ_PM => {
        'HTTP::Tiny' => '0.083',
        'URI'        => '5.05',
        'JSON::PP'   => '2.00',
        'Carp'       => 0,
    },

    TEST_REQUIRES => {
        'Test::More' => 0,
    },

    clean => {
        FILES => 'WWW-Crawl-*',
    },
);
