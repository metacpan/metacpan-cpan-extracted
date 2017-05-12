use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Yahoo::BBAuth',
    AUTHOR              => 'Jiro Nishiguchi <jiro@cpan.org> Jason Levitt <jlevitt@yahoo-inc.com>',
    VERSION_FROM        => 'lib/Yahoo/BBAuth.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'      => 0,
        'LWP'             => 5.6,
        'Class::Accessor' => 0,
        'JSON'            => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Yahoo-BBAuth-*' },
);
