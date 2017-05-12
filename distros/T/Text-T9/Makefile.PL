use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		      => 'Text::T9',
    'VERSION_FROM'	=> 'lib/Text/T9.pm',
    'PREREQ_PM'		  => {}, # e.g., Module::Name => 1.1
    
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Text/T9.pm', # retrieve abstract from module
       AUTHOR     => 'Vladi Belperchinov-Shabanski <cade@biscom.net>') : ()),
);
