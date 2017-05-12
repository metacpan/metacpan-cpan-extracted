use 5.006001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Tie::Hash::Vivify',
    META_MERGE => {
        license => 'other',
        resources => {
	    repository => 'https://github.com/DrHyde/perl-modules-Tie-Hash-Vivify',
	    bugtracker => 'https://github.com/DrHyde/perl-modules-Tie-Hash-Vivify/issues'
        }
    },
    VERSION_FROM      => 'lib/Tie/Hash/Vivify.pm',
    PREREQ_PM         => {},
);
