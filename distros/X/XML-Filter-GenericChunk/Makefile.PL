use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# $Id: Makefile.PL,v 1.3 2002/03/14 09:20:53 cb13108 Exp $

WriteMakefile(
              'NAME'		=> 'XML::Filter::GenericChunk',
              'VERSION_FROM'	=> 'GenericChunk.pm', # finds $VERSION
              'PREREQ_PM'		=> {
                                    XML::SAX::Base => 1.03,
                                    XML::LibXML => 1.40
                                   }, # e.g., Module::Name => 1.1
);
