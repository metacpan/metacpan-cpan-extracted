use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'            => 'Time::Elapse',
    
    'VERSION_FROM'    => 'Elapse.pm',             # finds $VERSION

    'PREREQ_PM'       => {                        # e.g., Module::Name => 1.1
                           Time::HiRes => 1.50 
                         }, 

    ($] > 5.005 ?                                 # Add these new keywords supported since 5.005
     (ABSTRACT_FROM => 'Elapse.pm',               # retrieve abstract from module
      AUTHOR        => 'Scott R. Godin <mactech@webdragon.net>'
     ) : ()
    ),
    
);
