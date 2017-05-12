use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::Summary::MediaWiki',
    AUTHOR              => 'David Leadbeater <dgl@dgl.cx>',
    VERSION_FROM        => 'lib/Text/Summary/MediaWiki.pm',
    ABSTRACT_FROM       => 'lib/Text/Summary/MediaWiki.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'HTML::Entities' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-Summary-MediaWiki-*' },
);
