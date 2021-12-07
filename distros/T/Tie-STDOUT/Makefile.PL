use 5.008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME      => 'Tie::STDOUT',
    META_MERGE => {
        license => 'open_source',
        resources => {
	    repository => 'https://github.com/DrHyde/perl-modules-Tie-STDOUT',
	    bugtracker => 'https://github.com/DrHyde/perl-modules-Tie-STDOUT/issues'
        }
    },
    VERSION_FROM => 'lib/Tie/STDOUT.pm',
    PREREQ_PM => {
        Devel::CheckOS => 0,
        File::Temp     => 0,
        Test::More     => 0.88, # done_testing
    }
);
