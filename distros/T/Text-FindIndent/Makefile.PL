use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Text::FindIndent',
    VERSION_FROM      => 'lib/Text/FindIndent.pm', # finds $VERSION
    PREREQ_PM         => {
      'Test::More'   => '0.80',
    }, # e.g., Module::Name => 1.1
    dist              => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Text/FindIndent.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),
);

