use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      'NAME'		=> 'Tk::MouseGesture',
	      'VERSION_FROM'	=> 'MouseGesture.pm', # finds $VERSION
	      'PREREQ_PM'	=> {}, # e.g., Module::Name => 1.1
	      ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       (ABSTRACT_FROM   => 'MouseGesture.pm', # retrieve abstract from module
		AUTHOR          => 'Ala Qumsieh <aqumsieh@cpan.org>') : ()),
	      PM                => {
				    'MouseGesture.pm' => '$(INST_LIB)/Tk/MouseGesture.pm',
				    'mousegesture.pl' => ($] >= 5.005 ?
							  '$(INST_ARCHLIB)' :
							  '$(INST_LIB)') .
				    '/Tk/demos/widtrib/mousegesture.pl',
				   },
	     );
