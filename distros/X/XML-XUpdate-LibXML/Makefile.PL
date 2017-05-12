# $Id: Makefile.PL,v 1.5 2003/09/29 10:36:37 pajas Exp $

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'XML::XUpdate::LibXML',
    'VERSION_FROM'	=> 'lib/XML/XUpdate/LibXML.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			    'XML::LibXML' => 1.54,
			    'XML::LibXML::Iterator' => 0,
			    'XML::LibXML::XPathContext' => 0.04
			   },
    'AUTHOR'            => 'Petr Pajas (pajas@matfyz.cz)',
    'ABSTRACT'          => 'update XML documents according to XUpdate file',
    'EXE_FILES'         => ['xupdate'],
);

