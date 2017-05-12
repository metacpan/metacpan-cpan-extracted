use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      'NAME'	=> 'Tie::NetAddr::IP',
	      'VERSION_FROM' => 'IP.pm', # finds $VERSION
	      'LIBS'	=> [''],   # e.g., '-lm' 
	      'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
	      'INC'	=> '',     # e.g., '-I/usr/include/other' 
	      'PREREQ_PM' => {
		  'NetAddr::IP' => 3,
		  'Carp' => 0,
		  'Test::More' => 0,
		  },
	      ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       (ABSTRACT_FROM	=> 'IP.pm',
		AUTHOR     	=> 'Luis E. Muñoz <lem@cantv.net>') : ()),
);
