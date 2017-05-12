use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Text::FixedLength::Extra',
    'VERSION_FROM'	=> 'Extra.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'Text::FixedLength' => 0.12 }, # e.g., Module::Name => 1.1
);
