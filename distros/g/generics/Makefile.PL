use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'generics',
    'VERSION_FROM'	=> 'lib/generics.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		"Test::More" => 0.47,
		"Test::Exception" => 0.15
		}
);
