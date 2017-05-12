use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Winamp::Control',
    'VERSION_FROM'	=> 'Control.pm', # finds $VERSION
    'PREREQ_PM'		=>
    {
    	LWP::Simple => 0,

    	URI => 0,

    	Class::Maker => 0,
    }, # e.g., Module::Name => 1.1

    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005

      (ABSTRACT_FROM => 'Control.pm', # retrieve abstract from module

       AUTHOR     => 'Murat UEnalan <murat.uenalan@gmx.de>') : ()
    ),
);
