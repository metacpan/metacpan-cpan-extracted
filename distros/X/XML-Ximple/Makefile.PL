use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'XML::Ximple',
    'VERSION_FROM'	=> 'Ximple.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'XML::Parser' => 2.30 }, # e.g., Module::Name => 1.1
);
