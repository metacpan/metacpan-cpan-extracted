use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile
 ( NAME	 	=> 'XML::Compile::Cache'
 , VERSION	=> '1.05'
 , PREREQ_PM    =>
   { XML::Compile              => 1.48
   , XML::Compile::Tester      => 0.02
   , XML::LibXML::Simple       => 0.95
   , Log::Report               => 0.19

   , Test::More                => 0.54
   }

 , EXE_FILES    => []
 , AUTHOR       => 'Mark Overmeer'
 , ABSTRACT     => 'Cache compiled XML translators'
 , LICENSE      => 'perl'
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
EXTENDS		= ../XMLCompile:../XMLSimple
RAWDIR          = ../public_html/xml-compile-cache/raw
DISTDIR         = ../public_html/xml-compile-cache/source
LICENSE         = artistic
SKIP_LINKS	= XML::LibXML

# for POD
FIRST_YEAR      = 2008
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/xml-compile/
PODTAIL		= ../XML-shared-podtail
__POSTAMBLE
