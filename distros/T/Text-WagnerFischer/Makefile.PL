use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      NAME		=> 'Text::WagnerFischer',
	      VERSION_FROM 	=> 'WagnerFischer.pm',
	      LINKTYPE		=> '$(INST_PM)',
	     );
