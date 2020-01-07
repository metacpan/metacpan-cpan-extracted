use ExtUtils::MakeMaker;

use 5.010;

WriteMakefile
 ( NAME	 	=> 'XML::Compile::SOAP::Mojolicious'
 , VERSION	=> '0.06'
 , PREREQ_PM    =>
   { XML::Compile::SOAP   => '3.16'
   , Log::Report          => '1.05'
   , Time::HiRes          => 0
   , HTTP::Message        => '6.06'
   , Mojolicious          => '8.25'
   , XML::Compile::WSDL11 => '3.00',
   , XML::Compile::SOAP12 => '3.00',
   }
 , AUTHOR       => 'Mark Overmeer <markov@overmeer.net>'
 , ABSTRACT     => 'SOAP with Mojolicious'
 , LICENSE      => 'perl_5'

 , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/markov2/perl5-XML-Compile-SOAP-Mojolicious.git'
              , web  => 'https://github.com/markov2/perl5-XML-Compile-SOAP-Mojolicious'
              }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

EXTENDS		= ../XML-Compile:../XML-Compile-SOAP-Daemon:../XML-Compile-Tester:../XML-Compile-Cache:../XML-Compile-SOAP12:../XML-Compile-SOAP

# for DIST
RAWDIR          = ../public_html/xml-compile-soap-mojolicious/raw
DISTDIR         = ../public_html/xml-compile-soap-mojolicious/source
SKIP_LINKS      = XML::LibXML

# for POD
FIRST_YEAR      = 2016
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/xml-compile/
__POSTAMBLE
