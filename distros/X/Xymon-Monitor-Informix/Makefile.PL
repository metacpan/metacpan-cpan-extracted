

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $hobbit = prompt("Where would you like ifxcheck.pl installed ", 
						"/home/hobbit/server/ext/");


WriteMakefile(
    NAME         => 'Xymon::Monitor::Informix',
    VERSION_FROM => 'lib/Xymon/Monitor/Informix.pm', # finds \$VERSION
    AUTHOR       => 'David Peters (davidp@electronf.com)',
    ABSTRACT     => 'Hobbit / Xymon Informix Database Monitor',
    INSTALLSITESCRIPT => $hobbit,
	EXE_FILES	=> ['lib/Xymon/Monitor/ifxcheck.pl'],
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Xymon::Client' => 0.01,
                     'DBI' => 0.1,
                     'DBD::Informix' => 0.1
                    },
    
);


print "
Please read the documentation. You will need to modify \$HOBBITHOME/server/etc/hobbitlaunchcfg
and include something like:
	
	[informix]
        ENVFILE /home/hobbit/server/etc/hobbitserver.cfg
        NEEDS hobbitd
        CMD /home/hobbit/server/ext/ifxcheck.pl
        LOGFILE \$BBSERVERLOGS/informix.log
        INTERVAL 1m

";
