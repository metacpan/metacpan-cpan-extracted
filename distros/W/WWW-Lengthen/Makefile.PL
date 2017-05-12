use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'WWW::Lengthen',
    AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
    VERSION_FROM  => 'lib/WWW/Lengthen.pm',
    ABSTRACT_FROM => 'lib/WWW/Lengthen.pm',
    PREREQ_PM => {
        'Carp'                => 0,
        'LWP::UserAgent'      => 0,
        'Test::More'          => 0.47,
        'Test::UseAllModules' => 0.09,
    },
    ($ExtUtils::MakeMaker::VERSION >= 6.31
        ? ( LICENSE => 'perl' )
        : ()
    ),
);
