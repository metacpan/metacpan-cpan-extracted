use 5.6.0;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'      => 'VBTK',
    'VERSION_FROM'  => 'VBTK.pm', # finds $VERSION
    'PREREQ_PM'     => {
        'Date::Manip'     => 0,
        'Algorithm::Diff' => 0,
        'Storable'        => 0,
        'File::Find'      => 0,
    },
    
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'VBTK.pm', # retrieve abstract from module
       AUTHOR     => 'Brent Henry <vbtoolkit@yahoo.com>') : ()),
);



