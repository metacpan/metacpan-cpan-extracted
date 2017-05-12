use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Wily',
    VERSION_FROM      => 'lib/Wily.pm', # finds $VERSION
    PREREQ_PM         => {
			'Encode' => '0',
			'Test::More' => '0',
			'Carp' => '0',
			'File::Temp' => '0',
			'IO::Socket' => '0',
			'Fcntl' => 0,
			}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Wily.pm', # retrieve abstract from module
       AUTHOR         => 'Sam Holden <sam@holden.id.au>') : ()),
);
