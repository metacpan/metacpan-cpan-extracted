use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::WordGrams',
    AUTHOR              => 'Alberto Simoes <ambs@cpan.org>',
    VERSION_FROM        => 'lib/Text/WordGrams.pm',
    ABSTRACT_FROM       => 'lib/Text/WordGrams.pm',
    PL_FILES            => {},
    PREREQ_PM => {
                  'File::Temp' => '0',
                  'DB_File' => '0',
                  'Lingua::PT::PLNbase' => '0.02',
                  'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-WordGrams-*' },
);
