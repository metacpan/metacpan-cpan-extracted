#!/usr/local/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
	      ABSTRACT_FROM => 'lib/XML/XSLT.pm',
	      ABSTRACT      => 'Conversion of XML files with XSLT.',
	      AUTHOR        => 'Geert Josten (gjosten@sci.kun.nl) and Egon Willighagen (egonw@sci.kun.nl)',
              NAME	    => 'XML::XSLT',
              dist          => { COMPRESS    => 'gzip',
				 SUFFIX      => '.gz'},
              VERSION_FROM  => 'lib/XML/XSLT.pm',
              PREREQ_PM     => { XML::Parser => '2.23',
				                     XML::DOM    => '1.25',
                                 Test::More  => '0.33' },
	      EXE_FILES      => ['xslt-parser'],
             );

