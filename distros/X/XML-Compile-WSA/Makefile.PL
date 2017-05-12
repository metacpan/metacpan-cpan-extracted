use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile
 ( NAME	 	=> 'XML::Compile::WSA'
 , VERSION	=> '0.94'

 , PREREQ_PM    =>
     { XML::Compile         => '1.49'
     , XML::Compile::Tester => '0.06'
     , XML::Compile::Cache  => '0.995'
     , XML::Compile::SOAP   => '3.00'
     , XML::Compile::WSDL11 => '3.00'
     , Log::Report          => '0.28'

     , Test::More           => 0.54
     , File::Spec           => 0
     , File::Basename       => 0
     }
 , EXE_FILES    => []
 , AUTHOR       => 'Mark Overmeer'
 , ABSTRACT     => 'SOAP Web Service Addressing'
 , LICENSE      => 'perl'
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/xml-compile-soap-wsa/raw
DISTDIR         = ../public_html/xml-compile-soap-wsa/source
LICENSE         = artistic

# for POD
FIRST_YEAR      = 2010
EMAIL           = perl@overmeer.net
EXTENDS         = ../XMLCompile:../XMLSOAP:../XMLTester
WEBSITE         = http://perl.overmeer.net/xml-compile/
PODTAIL		= ../XML-shared-podtail
__POSTAMBLE
