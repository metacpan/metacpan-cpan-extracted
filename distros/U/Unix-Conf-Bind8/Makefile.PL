use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'			=> 'Unix::Conf::Bind8',
    'VERSION_FROM'	=> 'Bind8.pm',
    'PREREQ_PM'		=> { Unix::Conf => 0.2 },
    'AUTHOR'		=> 'Karthik Krishnamurthy <karthik.k@extremix.net>'
);
