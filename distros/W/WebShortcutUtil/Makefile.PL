use 5.006_001;
use strict;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
# TODO: Need to add META_MERGE: See http://search.cpan.org/~dagolden/CPAN-Meta/lib/CPAN/Meta/Spec.pm
WriteMakefile(
    NAME              => 'WebShortcutUtil',
    VERSION_FROM      => 'lib/WebShortcutUtil.pm', # finds $VERSION
    PREREQ_PM         => {'Mac::PropertyList' => 0},
    LICENSE           => 'perl',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WebShortcutUtil.pm', # retrieve abstract from module
       AUTHOR         => 'Andre Beckus <beckus@cpan.org>') : ()),
);
