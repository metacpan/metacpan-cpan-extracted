use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile
 ( NAME	 	=> 'XML::Rewrite'
 , VERSION	=> '0.10'
 , PREREQ_PM    =>
   { XML::LibXML               => 1.65
   , XML::Compile::Tester      => 0.01
   , XML::Compile::Cache       => 0.13
   , XML::Compile              => 0.92

   , Test::More                => 0.54
   , Test::Pod                 => '1.00'
   }

 , EXE_FILES    =>
    [ 'bin/xmlrewrite'
    ]
 , AUTHOR       => 'Mark Overmeer'
 , ABSTRACT     => 'modify XML data'
 , LICENSE      => 'perl'
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
EXTENDS         = ../XMLCache:../XMLTester:../XMLCompile
RAWDIR          = ../public_html/xml-rewrite/raw
DISTDIR         = ../public_html/xml-rewrite/source
LICENSE         = artistic
SKIP_LINKS	= XML::LibXML

# for POD
FIRST_YEAR      = 2008
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/xml-compile/
PODTAIL		= ../XML-shared-podtail
__POSTAMBLE
