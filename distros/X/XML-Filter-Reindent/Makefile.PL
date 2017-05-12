use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'XML::Filter::Reindent',
    'VERSION_FROM'	=> 'Reindent.pm', # finds $VERSION
    'PREREQ_PM'		=> {XML::Filter::DetectWS => 0},
);
