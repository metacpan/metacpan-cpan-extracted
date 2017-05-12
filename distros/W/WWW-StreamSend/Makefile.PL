use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::StreamSend',
    VERSION_FROM      => 'lib/WWW/StreamSend.pm', # finds $VERSION
    PREREQ_PM         => {
        'XML::Simple'   => 0,
        'LWP'           => 0,
        'Carp'          => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/StreamSend.pm', # retrieve abstract from module
       AUTHOR         => 'Michael Katasonov <kabanoid@cpan.org>') : ()),
);
