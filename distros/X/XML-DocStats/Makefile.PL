use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'XML::DocStats',
    'VERSION_FROM'	=> 'lib/XML/DocStats.pm', # finds $VERSION
    'PREREQ_PM'		=> {XML::Parser::PerlSAX => 0.07,
                            XML::Parser => 2.30}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/XML/DocStats.pm', # retrieve abstract from module
       AUTHOR        => 'Alan Dickey <afdickey@intac.com>') : ()),
);
