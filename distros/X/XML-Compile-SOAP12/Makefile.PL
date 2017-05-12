use ExtUtils::MakeMaker;

use 5.010;

my $version = '3.04';

WriteMakefile
 ( NAME	 	=> 'XML::Compile::SOAP12'
 , VERSION	=> $version
 , PREREQ_PM    =>
   { XML::Compile         => '1.40'
   , XML::Compile::Tester => '0.05'
   , XML::Compile::Cache  => '0.995'
   , XML::Compile::SOAP   => '3.08'
   , Log::Report          => '0.90'

   , Time::HiRes     => 0
   , File::Basename  => 0

   , Test::More      => '0.54'
   , Test::Deep      => '0.095'
   }
 , AUTHOR       => 'Mark Overmeer'
 , ABSTRACT     => 'SOAP version 1.2'
 , LICENSE      => 'perl'
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

EXTENDS		= ../XMLCompile:../XMLSOAP:../XMLDaemon:../XMLTester

# for DIST
RAWDIR          = ../public_html/xml-compile-soap12/raw
DISTDIR         = ../public_html/xml-compile-soap12/source
LICENSE         = artistic
SKIP_LINKS	= XML::LibXML

# for POD
FIRST_YEAR      = 2009
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/xml-compile/
PODTAIL		= ../XML-shared-podtail
__POSTAMBLE
