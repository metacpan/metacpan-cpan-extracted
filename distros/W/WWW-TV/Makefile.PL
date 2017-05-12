use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::TV',
    VERSION_FROM      => 'lib/WWW/TV.pm',
    PREREQ_PM         => {
        LWP::UserAgent => 0, # any version should be fine
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/WWW/TV.pm',
       AUTHOR         => 'Danial Pearce <cpan@tigris.id.au>') : ()),
);
