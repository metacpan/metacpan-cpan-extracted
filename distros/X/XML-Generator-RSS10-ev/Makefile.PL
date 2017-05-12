use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'XML::Generator::RSS10::ev',
    'VERSION_FROM'	=> 'ev.pm', # finds $VERSION
    'PREREQ_PM'		=> { XML::Generator::RSS10 => 0.01, DateTime => 0.30, DateTime::Format::W3CDTF => 0.04, Params::Validate => 0.80 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'ev.pm', # retrieve abstract from module
       AUTHOR     => 'Andrew Green <andrew@article7.co.uk>') : ()),
);
