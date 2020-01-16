use ExtUtils::MakeMaker;

use 5.010;

WriteMakefile
 ( NAME	 	=> 'XML::Compile::WSA'
 , VERSION	=> '0.95'

 , PREREQ_PM    =>
     { XML::Compile         => '1.49'
     , XML::Compile::Tester => '0.06'
     , XML::Compile::Cache  => '0.995'
     , XML::Compile::SOAP   => '3.00'
     , XML::Compile::WSDL11 => '3.00'
     , Log::Report          => '0.28'

     , Test::More           => 0.54
     , File::Spec           => 0
     , File::Basename       => 0
     }
 , EXE_FILES    => []
 , ABSTRACT     => 'SOAP Web Service Addressing'
 , AUTHOR       => 'Mark Overmeer <markov@cpan.org>'
 , LICENSE      => 'perl_5'

 , META_MERGE   =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/markov2/perl5-XML-Compile-WSA.git'
              , web  => 'https://github.com/markov2/perl5-XML-Compile-WSA'
              }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/xml-compile-wsa/raw
DISTDIR         = ../public_html/xml-compile-wsa/source

# for POD
FIRST_YEAR      = 2010
EMAIL           = markov@cpan.org
EXTENDS         = ../XML-Compile:../XML-Compile-SOAP:../XML-Compile-Tester
WEBSITE         = http://perl.overmeer.net/CPAN/
__POSTAMBLE
