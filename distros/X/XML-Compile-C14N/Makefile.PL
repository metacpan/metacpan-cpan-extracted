use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile
 ( NAME	 	=> 'XML::Compile::C14N'
 , VERSION	=> '0.94'

 , PREREQ_PM    =>
     { XML::Compile         => '1.30'
     , XML::Compile::Cache  => '0.995'
     , XML::LibXML          => '1.94'
     , Scalar::Util         => 0

     , Log::Report          => '0.991'
     , Test::More           => '0.98'
     }
 , EXE_FILES    => []
 , AUTHOR       => 'Mark Overmeer'
 , ABSTRACT     => 'SOAP Web Service Addressing'
 , LICENSE      => 'perl'
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/xml-compile-c14n/raw
DISTDIR         = ../public_html/xml-compile-c14n/source
LICENSE         = artistic

# for POD
FIRST_YEAR      = 2011
EMAIL           = perl@overmeer.net
EXTENDS         = ../XMLCompile:../XMLCache
WEBSITE         = http://perl.overmeer.net/xml-compile/
PODTAIL		= ../XML-shared-podtail
__POSTAMBLE
