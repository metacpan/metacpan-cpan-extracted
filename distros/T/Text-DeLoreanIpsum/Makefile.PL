use 5.018002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME            => 'Text::DeLoreanIpsum',
    VERSION_FROM    => 'lib/Text/DeLoreanIpsum.pm', # finds $VERSION
    ABSTRACT_FROM   => 'lib/Text/DeLoreanIpsum.pm', # retrieve abstract from module
    AUTHOR          => 'Mariano Spadaccini (marianos)',
    LICENSE         => 'perl',
    PREREQ_PM     => {
        'List::MoreUtils'   => 0,
    },
);
