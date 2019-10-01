use 5.014002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'devtools',
    VERSION_FROM      => 'lib/devtools.pm', # finds $VERSION
    PREREQ_PM         => {
	'strict' => '1.11',
	'Exporter' => '5.73',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/devtools.pm', # retrieve abstract from module
       AUTHOR         => 'Armin Fuerst <armin@fuerst.priv.at>') : ()),
);
