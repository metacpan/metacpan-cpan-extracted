use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Text::Cipher',
    'VERSION_FROM'	=> 'Cipher.pm', # finds $VERSION
    'PREREQ_PM'		=> {
	Regexp::Tr => 0.05
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Cipher.pm', # retrieve abstract from module
       AUTHOR     => 'Robert Fischer <chia@localdomain>') : ()),
);
