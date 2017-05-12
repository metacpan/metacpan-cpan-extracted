use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Win32::IntAuth',
    VERSION_FROM      => 'lib/Win32/IntAuth.pm',
    PREREQ_PM         => {
        Win32::API => 0.41,
    },
    (
        $] >= 5.005
        ? (
            ABSTRACT_FROM  => 'lib/Win32/IntAuth.pm',
            AUTHOR         => 'Thomas Kratz <tomk@cpan.org>',
        )
        : ()
    ),
    (
        $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? (LICENSE => "perl")
        : (),
    ),
);
