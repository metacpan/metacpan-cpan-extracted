use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Time::Stopwatch',
    'VERSION_FROM'	=> 'Stopwatch.pm',
    'PREREQ_PM'		=> {},  # Time::HiRes is recommended
    ($] < 5.005 ? () :
       (ABSTRACT_FROM   => 'Stopwatch.pm',
        AUTHOR          => 'Ilmari Karonen <perl@itz.pp.sci.fi>')),
    'dist'              => {COMPRESS => 'gzip', SUFFIX => 'gz'}
);
