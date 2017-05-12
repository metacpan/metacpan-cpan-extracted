use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
          NAME	   => 'WWW::Promotion',
          VERSION_FROM => 'lib/WWW/Promotion.pm',
          PREREQ_PM    => { TAPORlib => 8.50 },
);
