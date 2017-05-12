use ExtUtils::MakeMaker;
use Config;

WriteMakefile(
    'NAME'         => 'Tie::Watch',
    'VERSION_FROM' => 'Watch.pm',
    ($] >= 5.005 ?
       (ABSTRACT   => 'Place watchpoints on Perl (and Tk) variables',
        AUTHOR     => 'Steve Lidie (Stephen.O.Lidie@Lehigh.EDU)') : ()),
    'dist'         => {COMPRESS => 'gzip', SUFFIX => 'gz'}
);
