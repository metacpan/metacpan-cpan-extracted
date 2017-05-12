use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile
 ( NAME	 	=> 'XML::Compile::SOAP::AnyEvent'
 , VERSION	=> '0.90'
 , PREREQ_PM    =>
   { XML::Compile::SOAP   => '3.05'
   , Log::Report          => '1.05'
   , Time::HiRes          => 0
   , AnyEvent::HTTP       => '1.46'
   , HTTP::Message        => '6.07'
   }
 , AUTHOR       => 'Aleksey Mashanov/Mark Overmeer'
 , ABSTRACT     => 'SOAP with AnyEvent'
 , LICENSE      => 'perl'
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

EXTENDS		= ../XMLCompile:../XMLDaemon:../XMLTester:../XMLCache:../XMLSOAP12:../XMLSOAP

# for DIST
RAWDIR          = ../public_html/xml-compile-soap-anyevent/raw
DISTDIR         = ../public_html/xml-compile-soap-anyevent/source
LICENSE         = artistic
SKIP_LINKS	= XML::LibXML

# for POD
FIRST_YEAR      = 2010
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/xml-compile/
PODTAIL		= ../XML-shared-podtail
__POSTAMBLE
