use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Tie::CharArray',
    'VERSION_FROM'	=> 'CharArray.pm',
    'PREREQ_PM'		=> {},
    ($] < 5.005 ? () :
       (ABSTRACT_FROM   => 'CharArray.pm',
        AUTHOR          => 'Ilmari Karonen <perl@itz.pp.sci.fi>')),
    'dist'              => {COMPRESS => 'gzip', SUFFIX => 'gz'}
);
