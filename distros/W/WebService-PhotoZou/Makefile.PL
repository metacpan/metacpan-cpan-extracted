use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WebService::PhotoZou',
    AUTHOR              => 'Jiro Nishiguchi <jiro@cpan.org>',
    VERSION_FROM        => 'lib/WebService/PhotoZou.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'      => 0.32,
        'LWP'             => 5.6,
        'Class::Accessor' => 0,
        'XML::Simple'     => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WebService-PhotoZou-*' },
);
