use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'X500::DN',
    'VERSION_FROM'	=> 'DN.pm', # finds $VERSION
    'PREREQ_PM'		=>
    {
	    'Parse::RecDescent' => '1.80',
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'DN.pod', # retrieve abstract from module
       AUTHOR     => 'Robert Joop <yaph-070708@timesink.de>') : ()),
);
