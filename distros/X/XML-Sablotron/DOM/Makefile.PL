use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> 'XML::Sablotron::DOM',
    'VERSION_FROM'	=> '../Sablotron.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    @extras,
);

