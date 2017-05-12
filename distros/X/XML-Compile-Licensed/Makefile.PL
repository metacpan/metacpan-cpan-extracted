use ExtUtils::MakeMaker;

use 5.008;

my $version = '0.01';

my $prereq =
   { XML::Compile         => '1.51'
   , File::Spec           => 0
   , File::Basename       => 0
   };

WriteMakefile
 ( NAME	 	=> 'XML::Compile::Licensed'
 , VERSION	=> $version
 , PREREQ_PM    => $prereq
 , AUTHOR       => 'Mark Overmeer'
 , ABSTRACT     => 'restricted XML files'
 , LICENSE      => 'perl'
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

EXTENDS		= ../XMLCompile:../XMLSOAP

# for DIST
RAWDIR          = ../public_html/xml-compile-licensed/raw
DISTDIR         = ../public_html/xml-compile-licensed/source
LICENSE         = artistic
SKIP_LINKS	= XML::LibXML

# for POD
FIRST_YEAR      = 2016
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/xml-compile/
PODTAIL		= ../XML-shared-podtail
__POSTAMBLE
