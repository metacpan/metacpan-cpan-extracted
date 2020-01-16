use ExtUtils::MakeMaker;

use 5.010;

WriteMakefile
 ( NAME	 	=> 'XML::Compile::C14N'
 , VERSION	=> '0.95'

 , PREREQ_PM    =>
     { XML::Compile         => '1.30'
     , XML::Compile::Cache  => '0.995'
     , XML::LibXML          => '1.94'
     , Scalar::Util         => 0

     , Log::Report          => '1.10'
     , Test::More           => '0.98'
     }
 , EXE_FILES    => []
 , AUTHOR       => 'Mark Overmeer <markov@cpan.org>'
 , ABSTRACT     => 'XML Canonicalization'
 , LICENSE      => 'perl_5'

 , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/markov2/perl5-XML-Compile-C14N.git'
              , web  => 'https://github.com/markov2/perl5-XML-Compile-C14N'
              }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/xml-compile-c14n/raw
DISTDIR         = ../public_html/xml-compile-c14n/source

# for POD
FIRST_YEAR      = 2011
EMAIL           = perl@overmeer.net
EXTENDS         = ../XML-Compile:../XML-Compile-Cache
WEBSITE         = http://perl.overmeer.net/xml-compile/
__POSTAMBLE
