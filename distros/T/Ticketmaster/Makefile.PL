use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Ticketmaster',
    VERSION_FROM      => 'lib/Ticketmaster.pm', # finds $VERSION
    PREREQ_PM         => {},
    ($] >= 5.005 ?
      (ABSTRACT  => 'Calculate the change in coins',
       AUTHOR         => 'Pan Yu <xiaocong[at]vip.163.com>') : ()),
	   LICENSE		      => 'Perl',
);

