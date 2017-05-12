use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'simpleXMLParse',
    VERSION_FROM      => 'lib/simpleXMLParse.pm', # finds $VERSION
    PREREQ_PM         => {'Test'        =>  0, }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      ( ABSTRACT          => "This is an XML Parser that is based on a recursive function and RE's. It generates a JSON-like Perl data structure that can be easily traversed.",
      AUTHOR            => "Daniel Edward Graham",
      LICENSE           => "perl_5",
       ) : ()),
);
