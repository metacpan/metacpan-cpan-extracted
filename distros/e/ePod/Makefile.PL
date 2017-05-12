###############
# MAKEFILE.PL #
###############

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'ePod' ,
    'VERSION_FROM'  => 'lib/ePod.pm' ,
    'EXE_FILES'     => [ qw(script/epod2pod.pl) ],
    ($] >= 5.005 ?
      ( ABSTRACT_FROM => 'lib/ePod.pm',
        AUTHOR        => 'Graciliano M. P. <gm@virtuasites.com.br>'
       ) : ()
     ),
);

1;

