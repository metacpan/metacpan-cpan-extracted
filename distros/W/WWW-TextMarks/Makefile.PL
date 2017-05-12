use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::TextMarks',
    VERSION_FROM      => 'lib/WWW/TextMarks.pm',
    PREREQ_PM         => {
                            LWP::Simple => 5,
                            XML::Simple => 2,
                          },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/WWW/TextMarks.pm',
       AUTHOR         => 'Dusty Wilson, <dusty@megagram.com>') : ()),
);
