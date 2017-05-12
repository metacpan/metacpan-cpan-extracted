use ExtUtils::MakeMaker;
use warnings;
use strict;

use 5.010;

# Signatures MUST be upgraded when installed

eval "require XML::Compile::WSS::Signature";
my $version = $XML::Compile::WSS::Signature::VERSION;

if(defined $version && $version lt '2.00')
{   warn <<__WARN;
*************
    You have XML::Compile::WSS::Signature version $version installed,
    but MUST upgrade it to at least version 2.00
*************
__WARN
    sleep 15
}

WriteMakefile
 ( NAME	 	=> 'XML::Compile::WSS'
 , VERSION	=> '1.14'

 , PREREQ_PM    =>
     { 'XML::Compile'         => '1.50'
     , 'XML::Compile::Cache'  => '1.00'
     , 'XML::Compile::SOAP'   => '3.00'
     , 'XML::Compile::WSDL11' => '3.00'
     , 'Log::Report'          => '0.92'

     , 'Encode'               => 0
     , 'Test::More'           => 0.54
     , 'File::Basename'       => 0
     , 'MIME::Base64'         => 0
     , 'Digest::SHA'          => 0
     , 'Scalar::Util'         => 0
     }
 , EXE_FILES    => []
 , AUTHOR       => 'Mark Overmeer'
 , ABSTRACT     => 'OASIS Web Services Security'
 , LICENSE      => 'perl'
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/xml-compile-wss/raw
DISTDIR         = ../public_html/xml-compile-wss/source
LICENSE         = artistic

# for POD
FIRST_YEAR      = 2011
EMAIL           = perl@overmeer.net
EXTENDS         = ../XMLCompile:../XMLCache:../XMLC14N:../WSSSIG
WEBSITE         = http://perl.overmeer.net/xml-compile/
PODTAIL		= ../XML-shared-podtail
__POSTAMBLE
