use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Twitter::TagGrep',
    AUTHOR              => 'Dave Sherohman <dave@sherohman.org>',
    VERSION_FROM        => 'lib/Twitter/TagGrep.pm',
    ABSTRACT_FROM       => 'lib/Twitter/TagGrep.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Twitter-TagGrep-*' },
);
