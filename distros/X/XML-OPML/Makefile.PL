use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'XML::OPML',
    'VERSION_FROM'	=> 'OPML.pm', # finds $VERSION
    'PREREQ_PM'		=> {
                            'XML::Parser' => '0',
                            'XML::SimpleObject' => '0',
                           }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'OPML.pm', # retrieve abstract from module
       AUTHOR     => 'michael szul <opml-dev@madghoul.com>') : ()),
);
