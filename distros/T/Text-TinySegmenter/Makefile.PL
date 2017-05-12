use 5.8.1;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::TinySegmenter',
    AUTHOR              => 'Jiro Nishiguchi <jiro@cpan.org>',
    VERSION_FROM        => 'lib/Text/TinySegmenter.pm',
    ABSTRACT_FROM       => 'lib/Text/TinySegmenter.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.31 ? ( LICENSE => 'bsd' ) : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-TinySegmenter-*' },
);

