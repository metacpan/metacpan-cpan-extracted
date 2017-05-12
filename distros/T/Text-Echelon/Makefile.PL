use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Text::Echelon',
    'VERSION_FROM' => 'Echelon.pm', # finds $VERSION
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Echelon.pm', # retrieve abstract from module
       AUTHOR     => 
	   'Russell Matbouli <text-echelon-makefile@russell.matbouli.org>') : ()),

);
