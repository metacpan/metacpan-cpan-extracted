use ExtUtils::MakeMaker;

use 5.010;

my $version = '3.24';

my $prereq =
   { XML::Compile         => '1.58'
   , XML::Compile::Tester => '0.90'
   , XML::Compile::Cache  => '1.03'
   , Log::Report          => '1.05'

   , LWP               => 6.08
   , Net::HTTP         => 6.16  # older versions contain nasty bugs
   , Time::HiRes       => 0
   , File::Slurp::Tiny => 0

   , Test::More        => 0.54
   };

eval "require XML::Compile::WSDL11";
if($@ !~ /can\'t locate/i)
{   my $v = $XML::Compile::WSDL11::VERSION || '3.00';

    # results in dependency loop, which CPAN.pm cannot handle
    #$prereq->{'XML::Compile::WSDL11'} = '3.00';

    if($v < 3.00) { warn <<'__CHANGES_300'; sleep 10 }
******************************************************************
WARNING: with XML::Compile::SOAP11 v3.00, the WSDL11 code got
   moved into a separate module.  You may need to add dependencies
   to that module as well.
******************************************************************
__CHANGES_300
}


eval "require XML::Compile::SOAP::Daemon";
if($@ !~ /can\'t locate/i)
{   my $v = $XML::Compile::SOAP::Daemon::VERSION || '3.08';

    if($v < 3.07) { warn <<'__CHANGES_307'; sleep 10 }
******************************************************************
WARNING: with XML::Compile::SOAP11 v3.08, the ::SOAP::Daemon code
   required some backwards compatibility (internal) changes.  You
   need to update XML::Compile::SOAP::Daemon
******************************************************************
__CHANGES_307

   sleep 10
}

WriteMakefile
 ( NAME	      => 'XML::Compile::SOAP'
 , VERSION    => $version
 , PREREQ_PM  => $prereq
 , AUTHOR     => 'Mark Overmeer <markov@cpan.org>'
 , ABSTRACT   => 'SOAP version 1.1'
 , LICENSE    => 'perl_5'

 , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/markov2/perl5-XML-Compile-SOAP.git'
              , web  => 'https://github.com/markov2/perl5-XML-Compile-SOAP'
              }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

EXTENDS		= ../XML-Compile:../../perl/XMLDaemon:../../perl/XMLTester:../XML-Compile-Cache:../../perl/XMLWSDL:../../perl/XMLSOAP12:../../perl/XMLSOAPEv:../../perl/XMLWSA

# for DIST
RAWDIR          = ../public_html/xml-compile-soap/raw
DISTDIR         = ../public_html/xml-compile-soap/source
SKIP_LINKS      = XML::LibXML

# for POD
FIRST_YEAR      = 2007
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/CPAN/

__POSTAMBLE
