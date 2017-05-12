use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tk::Spectrum',
    VERSION_FROM      => 'lib/Tk/Spectrum.pm', # finds $VERSION
    PREREQ_PM         => {
		'Tk'      => 0,
		'Tk::PNG' => 0,
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Tk/Spectrum.pm', # retrieve abstract from module
       AUTHOR         => 'Casey Kirsle <casey at cuvou.net>') : ()),
);
