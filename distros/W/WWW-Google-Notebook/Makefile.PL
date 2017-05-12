use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Google::Notebook',
    AUTHOR              => 'Jiro Nishiguchi <jiro@cpan.org>',
    VERSION_FROM        => 'lib/WWW/Google/Notebook.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'      => 0,
        'LWP'             => 5.6,
        'Class::Accessor' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Google-Notebook-*' },
);
