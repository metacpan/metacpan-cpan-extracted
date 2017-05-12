use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::Simpy',
    VERSION_FROM      => 'lib/WWW/Simpy.pm', # finds $VERSION
    PREREQ_PM         => {
                           strict => 1.03,
                           Exporter => 5.58,
                           AutoLoader => 5.60,
                           constant => 1.05,
                           LWP::UserAgent => 2.033,
			   XML::Parser => 2.34,
                           URI => 1.35,
			   Data::Dumper => 2.121
                           
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/Simpy.pm', # retrieve abstract from module
       AUTHOR         => 'Beads Land <beads@beadsland.com>') : ()),
);
