use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'XML::Generator::RSS10::lgcl',
    'VERSION_FROM'	=> 'lgcl.pm', # finds $VERSION
    'PREREQ_PM'		=> { XML::Generator::RSS10 => 0.01 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lgcl.pm', # retrieve abstract from module
       AUTHOR     => 'Andrew Green <andrew@article7.co.uk>') : ()),
);
