use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Text::Fold',
    AUTHOR        => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM  => 'lib/Text/Fold.pm',
    ABSTRACT_FROM => 'lib/Text/Fold.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'          => 0,
        'String::UnicodeUTF8' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Text-Fold-*' },
);
