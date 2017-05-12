use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Tie::StrictHash',
    'VERSION_FROM'	=> 'StrictHash.pm', # finds $VERSION
    'ABSTRACT_FROM'	=> 'StrictHash.pm',
    'AUTHOR'		=> 'Kevin Michael Vail <kevin@vaildc.net>',
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
);
