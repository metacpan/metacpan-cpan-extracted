use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'abbreviation',
    'VERSION_FROM' => 'lib/abbreviation.pm', # finds $VERSION
);
