use strict;
use warnings;
use 5.008008;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Test::Mock::Net::SNMP',
    VERSION_FROM => 'lib/Test/Mock/Net/SNMP.pm',    # finds $VERSION
    PREREQ_PM => { 'Readonly' => '0', 'Net::SNMP' => 0, 'Test::MockObject::Extends' => 0 },  # e.g., Module::Name => 1.1
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM => 'lib/Test/Mock/Net/SNMP.pm',     # retrieve abstract from module
            AUTHOR        => 'Rob Halliday <robh@cpan.org>'
          )
        : ()
    ),
);
