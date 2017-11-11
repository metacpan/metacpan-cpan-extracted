use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile
 ( NAME	 	=> 'XML::LibXML::Simple'
 , VERSION	=> '0.98'
 , PREREQ_PM    =>
   { XML::LibXML       => 1.64
   , Test::More        => 0.54
   , Scalar::Util      => 0
   }
 , AUTHOR       => 'Mark Overmeer'
 , ABSTRACT     => 'XML::LibXML based XML::Simple clone'
 , LICENSE      => 'perl'
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

RAWDIR          = ../public_html/xml-libxml-simple/raw
DISTDIR         = ../public_html/xml-libxml-simple/source
SKIP_LINKS      = XML::LibXML

# for POD
FIRST_YEAR      = 2008
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/xml-libxml-simple/
__POSTAMBLE
