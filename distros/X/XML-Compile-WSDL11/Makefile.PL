use ExtUtils::MakeMaker;

use 5.010;

my $version = '3.08';

my $prereq =
   { XML::Compile         => 1.48
   , XML::Compile::SOAP11 => 3.23
   , XML::Compile::Cache  => 1.03
   , XML::Compile::Tester => 0
   , Log::Report          => 1.05
   , Test::More           => 0.54
   };

WriteMakefile
 ( NAME	 	  => 'XML::Compile::WSDL11'
 , VERSION	  => $version
 , PREREQ_PM  => $prereq
 , AUTHOR     => 'Mark Overmeer <markov@cpan.org>'
 , ABSTRACT   => 'WSDL version 1.1'
 , LICENSE    => 'perl_5'

 , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
            { type => 'git'
            , url  => 'https://github.com/markov2/perl5-XML-Compile-WSDL11.git'
            , web  => 'https://github.com/markov2/perl5-XML-Compile-WSDL11'
            }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
EXTENDS         = ../XML-Compile-Cache:../XML-Compile-SOAP:../XML-Compile-SOAP12:../XML-Compile
RAWDIR          = ../public_html/xml-compile-wsdl11/raw
DISTDIR         = ../public_html/xml-compile-wsdl11/source
SKIP_LINKS      = XML::LibXML

# for POD
FIRST_YEAR      = 2014
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/CPAN/
__POSTAMBLE
