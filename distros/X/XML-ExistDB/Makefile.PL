use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile
 ( NAME	 	=> 'XML::ExistDB'
 , VERSION	=> '0.14'
 , PREREQ_PM    =>
   { XML::Compile              => 1.08
   , XML::Compile::Cache       => 0.995
   , XML::Compile::RPC         => 0.13
   , Log::Report               => 0.26
   , Time::HiRes               => 0
   , LWP::UserAgent            => 0
   , MIME::Base64              => 0
   , Test::More                => 0.54
   , Test::Pod                 => '1.00'
   }

 , EXE_FILES    => []
 , AUTHOR       => 'Mark Overmeer'
 , ABSTRACT     => 'ExistDB interface over XML-RPC'
 , LICENSE      => 'perl'
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
EXTENDS		= ../XMLCompile:../XMLCache:../XMLRPC
RAWDIR          = ../public_html/xml-existdb/raw
DISTDIR         = ../public_html/xml-existdb/source
LICENSE         = artistic
SKIP_LINKS	= XML::LibXML

# for POD
FIRST_YEAR      = 2010
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/xml-compile/
PODTAIL		= ../XML-shared-podtail
__POSTAMBLE
