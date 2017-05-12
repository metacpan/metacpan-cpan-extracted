use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use 5.008005;           # require perl 5.8.5

WriteMakefile(
    NAME              => 'Text::Positional::Ngram',
    VERSION_FROM      => 'Ngram.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'bthomson <bthomson@d.umn.edu>') : ()),
);
