use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile
 ( NAME	 	=> 'XML::Compile::Tester'
 , VERSION	=> '0.90'
 , PREREQ_PM    =>
   { Log::Report     => 0.17

   , Test::More      => 0.54
   , Test::Deep      => 0.095
   }
 , AUTHOR       => 'Mark Overmeer'
 , ABSTRACT     => 'support XML::Compile related regression testing'
 , LICENSE      => 'perl'
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/xml-compile-tester/raw
DISTDIR         = ../public_html/xml-compile-tester/source
LICENSE         = artistic
SKIP_LINKS	= XML::LibXML

# for POD
FIRST_YEAR      = 2008
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/xml-compile/
PODTAIL		= ../XML-shared-podtail
__POSTAMBLE
