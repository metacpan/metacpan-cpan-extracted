use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Text::Shift',
    'VERSION_FROM'	=> 'Shift.pm', # finds $VERSION
    'PREREQ_PM'		=> { 
	Crypt::Cipher => 0.02
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Shift.pm', # retrieve abstract from module
       AUTHOR     => 'Robert Fischer <chia@cpan.org>') : ()),
);
