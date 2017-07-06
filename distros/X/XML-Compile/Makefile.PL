use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile
 ( NAME	 	=> 'XML::Compile'
 , VERSION	=> '1.58'

 , PREREQ_PM    =>
   { XML::LibXML               => 2.0107
   , XML::Compile::Tester      => 0.90
   , IO                        => 1.22
   , Log::Report               => 1.20

   , Math::BigInt              => 1.77
   , Math::BigRat              => 0.10
   , bignum                    => 0.10
   , Digest::MD5               => 2.36
   , List::Util                => 0
   , MIME::Base64              => 3.10
   , Types::Serialiser         => 0

   , Test::More                => 0.54
   , Test::Deep                => 0.095
   }

 , EXE_FILES    =>
   [ 'bin/xml2yaml'
   , 'bin/xml2json'
   , 'bin/schema2example'
   ]
 , AUTHOR       => 'Mark Overmeer'
 , ABSTRACT     => 'Compilation based XML processing'
 , LICENSE      => 'perl'
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/xml-compile/raw
DISTDIR         = ../public_html/xml-compile/source
LICENSE         = artistic
SKIP_LINKS      = XML::LibXML

# for POD
EXTENDS		= ../XMLSOAP:../XMLSOAP12:../XMLDaemon:../XMLDumper:../XMLCache:../XMLSimple:../XMLTester:../XMLRewrite:../XMLRPC:../XMLSOAPEv:../XMLC14N:../XMLWSS:../WSSSIG:../XMLWSDL:../XMLSOAPMo:../XMLSOAPLi
FIRST_YEAR      = 2006
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/xml-compile/
PODTAIL         = ../XML-shared-podtail

# for HTML
HTML_OUTPUT     = ../public_html/xml-compile/html
HTML_DOCROOT    = /xml-compile/html
HTML_PACKAGE    = ../public_html/xml-compile/htmlpkg

__POSTAMBLE
