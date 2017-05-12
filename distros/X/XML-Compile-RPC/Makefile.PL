use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile
 ( NAME	 	=> 'XML::Compile::RPC'
 , VERSION	=> '0.17'
 , PREREQ_PM    =>
   { XML::Compile              => 1.08
   , XML::Compile::Cache       => 0.92
   , XML::Compile::Tester      => 0.05
   , Log::Report               => 0.28
   , Time::HiRes               => 0
   , LWP::UserAgent            => 0

   , Test::More                => 0.54
   }

 , EXE_FILES    => []
 , AUTHOR       => 'Mark Overmeer'
 , ABSTRACT     => 'XML-RPC client'
 , LICENSE      => 'perl'
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
EXTENDS		= ../XMLCompile:../XMLCache
RAWDIR          = ../public_html/xml-compile-rpc/raw
DISTDIR         = ../public_html/xml-compile-rpc/source
LICENSE         = artistic
SKIP_LINKS	= XML::LibXML

# for POD
FIRST_YEAR      = 2009
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/xml-compile/
PODTAIL		= ../XML-shared-podtail
__POSTAMBLE
