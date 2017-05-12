# @(#) $Id: Makefile.PL,v 1.3 2003/04/24 12:58:17 dom Exp $
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'XML::SAX::Builder',
    VERSION_FROM => 'lib/XML/SAX/Builder.pm',
    PL_FILES     => {},                    # ignore Build.PL
    PREREQ_PM    => {
        'Test::More'            => 0,
        'XML::NamespaceSupport' => 0,
        'XML::SAX::Writer'      => 0,
    },
);
