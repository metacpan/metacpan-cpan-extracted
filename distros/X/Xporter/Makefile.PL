

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Xporter',
    VERSION_FROM => 'lib/Xporter.pm',
    AUTHOR       => 'LA Walsh (LAWALSH@cpan.org)',
    ABSTRACT     => "Alt. exporter w/persistent, dflts & auto ISA",
    BUILD_REQUIRES=> { 'ExtUtils::MakeMaker' => '6.86', },
    CONFIGURE_REQUIRES=> { 'ExtUtils::MakeMaker' => '6.86', },
		TEST_REQUIRES =>
								 => { 'Test::Simple' => '0.44', mem	=> '0.4.5' },
		dist         => { TAR=> 'tar', TARFLAGS=> "-H v7 -h -cf " },

);
