use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'XML::Tidy::Tiny',
    VERSION_FROM      => 'lib/XML/Tidy/Tiny.pm', # finds $VERSION
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/XML/Tidy/Tiny.pm', # retrieve abstract from module
       AUTHOR         => 'A. G. Grishayev <grian@cpan.org>') : ()),
);
