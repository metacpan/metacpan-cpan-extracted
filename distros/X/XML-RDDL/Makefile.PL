use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'XML::RDDL',
    'VERSION_FROM'  => 'RDDL.pm',
    'AUTHOR'        => 'Robin Berjon',
    'ABSTRACT'      => 'Interface to RDDL (http://www.rddl.org/)',
    'PREREQ_PM'     => {
                        XML::SAX    => '0.00',
                       },
);
