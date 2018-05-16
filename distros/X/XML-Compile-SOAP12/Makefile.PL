use ExtUtils::MakeMaker;

use 5.010;

my $version = '3.06';

WriteMakefile
 ( NAME	 	=> 'XML::Compile::SOAP12'
 , VERSION	=> $version
 , PREREQ_PM    =>
   { XML::Compile         => '1.40'
   , XML::Compile::Tester => '0.05'
   , XML::Compile::Cache  => '0.995'
   , XML::Compile::SOAP   => '3.08'
   , Log::Report          => '0.90'

   , Time::HiRes     => 0
   , File::Basename  => 0

   , Test::More      => '0.54'
   , Test::Deep      => '0.095'
   }

 , AUTHOR     => 'Mark Overmeer <markov@cpan.org>'
 , ABSTRACT   => 'SOAP version 1.2'
 , LICENSE    => 'perl_5'

 , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
            { type => 'git'
            , url  => 'https://github.com/markov2/perl5-XML-Compile-SOAP12.git'
            , web  => 'https://github.com/markov2/perl5-XML-Compile-SOAP12'
            }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

EXTENDS         = ../XML-Compile:../XML-Compile-SOAP:../../perl/XMLDaemon:../../perl/XMLTester

# for DIST
RAWDIR          = ../public_html/xml-compile-soap12/raw
DISTDIR         = ../public_html/xml-compile-soap12/source
SKIP_LINKS      = XML::LibXML

# for POD
FIRST_YEAR      = 2009
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/xml-compile/
__POSTAMBLE
