use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile
 ( NAME	 	=> 'XML::Compile::SOAP::Mojolicious'
 , VERSION	=> '0.02'
 , PREREQ_PM    =>
   { XML::Compile::SOAP   => '3.16'
   , Log::Report          => '1.05'
   , Time::HiRes          => 0
   , HTTP::Message        => '6.06'
   , Mojolicious          => '6.00'
   }
 , AUTHOR       => 'Heiko Jansen/Mark Overmeer'
 , ABSTRACT     => 'SOAP with Mojolicious'
 , LICENSE      => 'perl'
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

EXTENDS		= ../XMLCompile:../XMLDaemon:../XMLTester:../XMLCache:../XMLSOAP12:../XMLSOAP

# for DIST
RAWDIR          = ../public_html/xml-compile-soap-mojolicious/raw
DISTDIR         = ../public_html/xml-compile-soap-mojolicious/source
LICENSE         = artistic
SKIP_LINKS	= XML::LibXML

# for POD
FIRST_YEAR      = 2016
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/xml-compile/
PODTAIL		= ../XML-shared-podtail
__POSTAMBLE
