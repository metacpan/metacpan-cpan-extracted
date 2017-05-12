use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'XML::Beautify',
    'VERSION_FROM'	=> './lib/XML/Beautify.pm', # finds $VERSION
    'LIBS'		=> [''], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '', # e.g., '-I/usr/include/other'
	'PREREQ_PM'		=> { 
			Log::AndError => 0.99,# e.g., Module::Name => 1.1
			XML::Parser::Expat => 2.00,
                       },

#    ($] < 5.005 ? () : 
#      (ABSTRACT_FROM => './lib/XML/Beautify.pm', # retrieve abstract from module
#       AUTHOR     => 'Thomas Bolioli <Thomas_Bolioli@alumni.adelphi.edu>') 
#    ),
);

