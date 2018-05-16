use ExtUtils::MakeMaker;

use 5.010;

WriteMakefile
 ( NAME	 	=> 'XML::Rewrite'
 , VERSION	=> '0.11'
 , PREREQ_PM    =>
   { XML::LibXML               => 1.65
   , XML::Compile::Tester      => 0.01
   , XML::Compile::Cache       => 0.13
   , XML::Compile              => 0.92

   , Test::More                => 0.54
   , Test::Pod                 => '1.00'
   }

 , EXE_FILES  =>
   [ 'bin/xmlrewrite'
   ]
 , AUTHOR     => 'Mark Overmeer <markov@cpan.org>'
 , ABSTRACT   => 'modify XML data'
 , LICENSE    => 'perl_5'

 , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/markov2/perl5-XML-Rewrite.git'
              , web  => 'https://github.com/markov2/perl5-XML-Rewrite'
              }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
EXTENDS         = ../XML-Compile-Cache:../../perl/XMLTester:../XML-Compile
RAWDIR          = ../public_html/xml-rewrite/raw
DISTDIR         = ../public_html/xml-rewrite/source
SKIP_LINKS      = XML::LibXML

# for POD
FIRST_YEAR      = 2008
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/CPAN/
__POSTAMBLE
