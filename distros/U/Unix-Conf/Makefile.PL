use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'			=> 'Unix::Conf',
    'VERSION_FROM'	=> 'Conf.pm',
    'PREREQ_PM'		=> { Fcntl	=> 1.03 },
    'AUTHOR'		=> 'Karthik Krishnamurthy <karthik.k@extremix.net>'
);
