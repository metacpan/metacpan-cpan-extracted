#!/usr/bin/env perl
use ExtUtils::MakeMaker;

use 5.008;

my $version = '2.02';

WriteMakefile
 ( NAME	 	=> 'XML::Compile::WSS::Signature'
 , VERSION	=> $version

 , PREREQ_PM    =>
     { XML::Compile         => '1.29'
     , XML::Compile::Cache  => '0.995'
     , XML::Compile::SOAP   => '2.33'
     , XML::Compile::C14N   => '0.93'
     , XML::Compile::WSS    => '1.13'

     , Log::Report          => '0.92'
     , Test::More           => 0.54
     , Encode               => 0
     , Scalar::Util         => 0
     , XML::LibXML          => '2.00'  # newer than overload bug

     , Digest               => 0
     , Digest::SHA1         => 0
     , Digest::HMAC_SHA1    => 0
     , MIME::Base64         => 0

     , File::Basename       => 0
     , File::Slurp          => 0
     , File::Glob           => 0

     , Crypt::OpenSSL::RSA  => 0
     , Crypt::OpenSSL::X509 => '1.803'
     }

 , EXE_FILES    => []
 , AUTHOR       => 'Mark Overmeer'
 , ABSTRACT     => 'OASIS WSS Signatures'
 , LICENSE      => 'perl'
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/xml-compile-wss-signature/raw
DISTDIR         = ../public_html/xml-compile-wss-signature/source
LICENSE         = artistic

# for POD
FIRST_YEAR      = 2012
EMAIL           = perl@overmeer.net
EXTENDS         = ../XMLCompile:../XMLCache:../XMLWSS:../XMLC14N
WEBSITE         = http://perl.overmeer.net/xml-compile/
PODTAIL		= ../XML-shared-podtail
SKIP_LINKS	= XML::LibXML
__POSTAMBLE
