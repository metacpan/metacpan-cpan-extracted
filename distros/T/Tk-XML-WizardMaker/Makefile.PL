use 5.0;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Tk::XML::WizardMaker',
    'VERSION_FROM'	=> 'WizardMaker.pm', 
    'PREREQ_PM'		=> {XML::Simple => '1.0', Tk => '8.0', }, 
    ($] >= 5.005 ?      ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM    => 'WizardMaker.pm', # retrieve abstract from module
       AUTHOR           => 'Viktor Zimmermann <ZiMTraining@gmx.net>') : ()),
);
