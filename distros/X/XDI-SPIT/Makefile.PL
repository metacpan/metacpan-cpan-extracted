use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'XDI::SPIT',
    'VERSION_FROM'	=> 'SPIT.pm',
    'PREREQ_PM'		=> {
        'LWP' => 1.35,
        'URI::Escape' => 3.21,
        'XRI' => 0.2,
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT => 'XDI::SPIT support libraries',
       AUTHOR   => 'Eugene Eric Kim <eekim@blueoxen.org>') : ()),
);
