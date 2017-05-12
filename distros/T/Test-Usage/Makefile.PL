use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile (
    NAME          => 'Test::Usage',
    VERSION_FROM  => 'lib/Test/Usage.pm',
    PREREQ_PM => {
        IO::Capture::Stderr => 0,
        IO::Capture::Stdout => 0,
        File::Slurp => 0,
    },
    ABSTRACT_FROM  => 'lib/Test/Usage.pm',
    AUTHOR         => 'Luc St-Louis <lucs@cpan.org>',
);

