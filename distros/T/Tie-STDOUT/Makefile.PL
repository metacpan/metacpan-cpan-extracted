use 5.008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME      => 'Tie::STDOUT',
    VERSION_FROM => 'lib/Tie/STDOUT.pm',
    PREREQ_PM => {
        File::Temp => 0, # all used for testing only
        Test::More => 0,
        Config     => 0
    }
);
