use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::MultiMarkdown::ApacheHandler',
    AUTHOR              => 'Darren Kulp <darren@kulp.ch>',
    VERSION_FROM        => 'lib/Text/MultiMarkdown/ApacheHandler.pm',
    ABSTRACT_FROM       => 'lib/Text/MultiMarkdown/ApacheHandler.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Apache::Constants' => 0,
        'Apache::File' => 0,
        'CGI' => 0,
        'Text::MultiMarkdown' => 0,
        'Text::Typography' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-MultiMarkdown-ApacheHandler-*' },
);
