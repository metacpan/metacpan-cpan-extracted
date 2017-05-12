

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Xymon::Monitor::SNMP',
    VERSION_FROM => 'lib/Xymon/Monitor/SNMP.pm', # finds \$VERSION
    AUTHOR       => 'David Peters (davidp@electronf.com)',
    ABSTRACT     => 'Xymon Interface to SNMP',
    PREREQ_PM    => {
                     	'Test::Simple' => 0.44,
		     			'Net::SNMP' => 6.0.0
		     		},
);
