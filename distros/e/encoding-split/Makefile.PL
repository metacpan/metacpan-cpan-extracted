use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'encoding::split',
    VERSION_FROM      => 'lib/encoding/split.pm', # finds $VERSION
    PREREQ_PM         => {
        'encoding::stdio' => '0.02',
        'encoding::source' => '0.02',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/encoding/split.pm', # retrieve abstract from module
       AUTHOR         => 'Juerd Waalboer <juerd@cpan.org>') : ()),
);
