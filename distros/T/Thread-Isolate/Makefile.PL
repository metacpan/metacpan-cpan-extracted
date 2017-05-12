###############
# MAKEFILE.PL #
###############

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Thread::Isolate' ,
    'VERSION_FROM'  => 'lib/Thread/Isolate.pm' ,
    #'PREREQ_PM'     => {'Foo'  => 0.01} ,
    ($] >= 5.005 ?
      ( ABSTRACT_FROM => 'lib/Thread/Isolate.pm',
        AUTHOR        => 'Graciliano M. P. <gmpassos@cpan.org>'
       ) : ()
     ),
);

1;

