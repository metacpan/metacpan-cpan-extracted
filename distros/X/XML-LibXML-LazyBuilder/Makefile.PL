use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'XML::LibXML::LazyBuilder',
    VERSION_FROM      => 'lib/XML/LibXML/LazyBuilder.pm', # finds $VERSION
    PREREQ_PM         => {XML::LibXML => 0}, # e.g., Module::Name => 1.1
    LICENSE           => 'perl',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/XML/LibXML/LazyBuilder.pm', # retrieve abstract from module
       AUTHOR         => 'Toru Hisai <toru@cpan.org>') : ()),

    PREREQ_FATAL => 0,
    dist => { PREOP => 'pod2text lib/XML/LibXML/LazyBuilder.pm > README' },
);
