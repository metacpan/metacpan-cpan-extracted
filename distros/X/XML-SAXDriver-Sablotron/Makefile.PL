use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	      NAME	=> 'XML::SAXDriver::Sablotron',
	      AUTHOR    => 'Pavel Hlavnicka (pavel@gingerall.cz)',
	      ABSTRACT  => 'Sablotron XSLT processor SAX2 outputter',
	      VERSION_FROM => 'Sablotron.pm', 
	      PREREQ_PM	=> { XML::Sablotron => 0.90},
	      dist	=> {COMPRESS => 'gzip', SUFFIX => 'tar.gz'},
	      LIBS	=> [''], # e.g., '-lm'
	      DEFINE	=> '', # e.g., '-DHAVE_SOMETHING'
	      INC	=> '', # e.g., '-I/usr/include/other'
);
