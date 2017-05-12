

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Xymon::Server::Status',
    VERSION_FROM => 'lib/Xymon/Server/Status.pm', # finds \$VERSION
    AUTHOR       => 'David Peters (davidp@electronf.com)',
    ABSTRACT     => 'Retrieve Status of Hosts and Tests',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
