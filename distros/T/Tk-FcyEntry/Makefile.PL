use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tk::FcyEntry',
    VERSION_FROM      => 'lib/Tk/FcyEntry.pm', # finds $VERSION
    PREREQ_PM         => {
        ExtUtils::MakeMaker => '6.64',   # for #! fixing
		Tk => '402.002',		      # opt. aliases
    }, # e.g., Module::Name => 1.1
    TEST_REQUIRES => {
        Test::More => '1.001003',
    },
    ABSTRACT_FROM  => 'lib/Tk/FcyEntry.pm', # retrieve abstract from module
    AUTHOR         => 'Alexander Becker <asb@cpan.org>',
);
