use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'XML::Filter::DetectWS',
    'VERSION_FROM'	=> 'DetectWS.pm', # finds $VERSION
    'PREREQ_PM'		=> { XML::Filter::SAXT => 0 },
);
