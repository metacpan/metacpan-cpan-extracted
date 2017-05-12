use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'GD::RPPNG',
    'VERSION_FROM'	=> 'RPPNG.pm', # finds $VERSION
    'PREREQ_PM'		=> { GD => 2.11 }, # e.g., Module::Name => 1.1
);
