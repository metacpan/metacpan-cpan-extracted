use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tridion::BusinessConnector',
    VERSION_FROM      => 'lib/Tridion/BusinessConnector.pm', # finds $VERSION
    PREREQ_PM         => {
                          'Test::More' => 0,
                          'XML::LibXML' => 1.5,
                          'SOAP::Lite' => 0.6
                         },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (
       ABSTRACT_FROM  => 'lib/Tridion/BusinessConnector.pm', # retrieve abstract from module
       AUTHOR         => 'Toby Corkindale <cpan@corkindale.net>') : ()
      ),
);
