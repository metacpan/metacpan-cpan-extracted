use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile
 ( NAME	 	=> 'XML::Compile::Dumper'
 , VERSION	=> '0.14'
 , PREREQ_PM    =>
   { XML::LibXML               => 1.63
   , Data::Dump::Streamer      => 2.08
   , XML::Compile              => 0.64
   , XML::Compile::Tester      => 0.01
   , Math::BigInt              => 1.77
   , Log::Report               => 0.09
   , Test::More                => 0.54
   , Test::Pod                 => '1.00'
   }
 , AUTHOR       => 'Mark Overmeer'
 , ABSTRACT     => 'Remember precompiled XML processors'
 , LICENSE      => 'perl'
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/xml-compile-dumper/raw
DISTDIR         = ../public_html/xml-compile-dumper/source
LICENSE         = artistic

FIRST_YEAR      = 2007
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/xml-compile/
PODTAIL		= ../XML-shared-podtail

# for HTML
HTML_OUTPUT     = ../public_html/xml-compile/html
HTML_DOCROOT    = /xml-compile/html
HTML_PACKAGE    = ../public_html/xml-compile/htmlpkg

__POSTAMBLE
