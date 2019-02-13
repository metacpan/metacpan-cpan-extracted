use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Text::JSCalendar',
    AUTHOR           => q{Bron Gondwana <brong@cpan.org>},
    VERSION_FROM     => 'lib/Text/JSCalendar.pm',
    ABSTRACT_FROM    => 'lib/Text/JSCalendar.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'DateTime::TimeZone' => 0,
        'Data::ICal::TimeZone' => '1.23',
        'DateTime::Format::ISO8601' => '0.08',
        'DateTime::Format::ICal' => '0.09',
        'Text::LevenshteinXS' => '0.03',
        'Text::VCardFast' => '0.06',
        'JSON' => 0,
        'JSON::XS' => 0,
        'MIME::Types' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Text-JSCalendar-*' },
);

