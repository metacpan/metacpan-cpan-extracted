use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'XML::Parser::Style::RDF',
    'VERSION_FROM'	=> 'RDF.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'XML::Parser' => 2 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'RDF.pm', # retrieve abstract from module
       AUTHOR     => 'Ashley Winters <awinters@users.sourceforge.net>') : ()),
);
