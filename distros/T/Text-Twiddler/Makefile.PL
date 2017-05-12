use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::Twiddler',
    AUTHOR              => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM        => 'lib/Text/Twiddler.pm',
    ABSTRACT_FROM       => 'lib/Text/Twiddler.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'  => 0,
        'version'     => 0,
        'Class::Std'  => 0,
        'Class::Std::Utils'  => 0,
        'Locale::Maketext::Pseudo' => 0,
        'List::Cycle' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-Twiddler-*' },
);
