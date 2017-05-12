use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Yada::Yada::Yada',
    'VERSION_FROM'	=> 'Yada.pm', 
    'PREREQ_PM'		=> {
                             'Filter::Simple' => 0.76,
                             'Test::Simple'   => 0.01,
                           }, 
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Yada.pm', # retrieve abstract from module
       AUTHOR     => 'Tony Bowden <tony@tmtm.com>') : ()),
);
