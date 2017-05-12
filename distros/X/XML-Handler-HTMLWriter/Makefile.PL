# $Id: Makefile.PL,v 1.4 2003/03/30 09:35:36 matt Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'XML::Handler::HTMLWriter',
    'VERSION_FROM'	=> 'HTMLWriter.pm', # finds $VERSION
    'AUTHOR'            => 'Matt Sergeant',
    'ABSTRACT'          => 'HTML Output from XHTML SAX events',
    'PREREQ_PM'         => {
        HTML::Entities => 1.22,
        XML::SAX::Writer => 0.44,
    },
);
