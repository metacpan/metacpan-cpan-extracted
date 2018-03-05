use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile
 ( NAME	 	=> 'XML::Compile::Cache'
 , VERSION	=> '1.06'
 , PREREQ_PM    =>
   { XML::Compile              => 1.60
   , XML::Compile::Tester      => 0.02
   , XML::LibXML::Simple       => 0.95
   , Log::Report               => 1.26

   , Test::More                => 0.54
   }

 , AUTHOR     => 'Mark Overmeer'
 , ABSTRACT   => 'Cache compiled XML translators'
 , LICENSE    => 'perl_5'

 , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/markov2/perl5-XML-Compile-Cache.git'
              , web  => 'https://github.com/markov2/perl5-XML-Compile-Cache'
              }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
EXTENDS     = ../XML-Compile:../../perl/XMLSimple
RAWDIR      = ../public_html/xml-compile-cache/raw
DISTDIR     = ../public_html/xml-compile-cache/source
SKIP_LINKS  = XML::LibXML

# for POD
FIRST_YEAR  = 2008
EMAIL       = markov@cpan.org
WEBSITE     = http://perl.overmeer.net/xml-compile/
__POSTAMBLE
