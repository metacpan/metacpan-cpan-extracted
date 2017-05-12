
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	'NAME'		=>	'URI::Sequin',
	'PM'		=>	{ 'Sequin.pm' => '$(INST_LIBDIR)/Sequin.pm',},
	'PREREQ_PM'	=>	{},
	'VERSION_FROM'	=>	'Sequin.pm', # finds $VERSION
);
