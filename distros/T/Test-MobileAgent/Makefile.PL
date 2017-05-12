use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Test::MobileAgent',
    AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
    VERSION_FROM  => 'lib/Test/MobileAgent.pm',
    ABSTRACT_FROM => 'lib/Test/MobileAgent.pm',
    PREREQ_PM => {
        'HTTP::MobileAgent'   => '0.28',
        'HTTP::Headers::Fast' => '0',
        'List::Util'          => '0',
        'Test::More'          => '0.88', # for done_testing
        'Test::UseAllModules' => '0.10',
    },
    ($ExtUtils::MakeMaker::VERSION >= 6.31
        ? ( LICENSE => 'perl' )
        : ()
    ),
);
