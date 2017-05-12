###############
# MAKEFILE.PL #
###############

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'lib::http' ,
    'VERSION_FROM'  => 'lib/lib/http.pm' ,
    'PREREQ_PM'     => {
    'LibZip'          => 0.06 ,
    'Compress::Zlib'  => 1.20 ,
    } ,
    'EXE_FILES'     => [ qw(script/libhttp) ],
    ($] >= 5.005 ?
      ( ABSTRACT_FROM => 'lib/lib/http.pm',
        AUTHOR        => 'Graciliano M. P. <gmpassos@cpan.org>'
       ) : ()
     ),
);

1;


