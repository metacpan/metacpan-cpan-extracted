# $Id: Makefile.PL,v 1.1.1.1 2003/12/04 20:40:43 mrodrigu Exp $

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'XML::DOM::XPath',
    VERSION_FROM      => 'XPath.pm', # finds $VERSION
    PREREQ_PM         => { XML::DOM => 0, XML::XPathEngine => 0.10 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'XPath.pm', # retrieve abstract from module
       AUTHOR         => 'Michel Rodriguez <mirod@cpan.org>') : ()),
);

