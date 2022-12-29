use ExtUtils::MakeMaker;

use 5.010;

my $version = '3.15';

my $devel   = exists $ENV{MARKOV_DEVEL};

my %prereq  =
  ( XML::Compile         => 1.44
  , XML::Compile::SOAP   => '3.00'
  , XML::Compile::WSDL11 => '3.00'
  , XML::Compile::Tester => '0.90'
  , XML::Compile::Cache  => 0.991

  , Log::Report     => 1.23
  , Time::HiRes     => 0
  , Test::More      => 0.54

# Only needed when ::Daemon::NetServer is being used
# , Net::Server     => 0.97
# , HTTP::Daemon    => 6.0
# , HTTP::Message   => 6.0

# Only needed when ::Daemon::AnyDaemon is being used
# , Any::Daemon     => 0.13
# , HTTP::Daemon    => 6.0
# , HTTP::Message   => 6.0

# Only needed when SSL is used
# , IO::Socket::SSL   => 0
# , HTTP::Daemon::SSL => 1.04
  );

# only update WSA if installed
eval "require XML::Compile::WSA";
unless($@ || $devel)
{   my $v = $XML::Compile::WSA::VERSION || '';
    $prereq{'XML::Compile::WSA'} = '0.90';
}

eval "require XML::Compile::SOAP12";
unless($@ || $devel)
{   my $v = $XML::Compile::SOAP12::VERSION || '';
    $prereq{'XML::Compile::SOAP12'} = '3.01';
}

WriteMakefile
 ( NAME	 	  => 'XML::Compile::SOAP::Daemon'
 , VERSION	  => $version
 , PREREQ_PM  => \%prereq
 , AUTHOR     => 'Mark Overmeer <markov@cpan.org>'
 , ABSTRACT   => 'Daemon handling XML-SOAP'
 , LICENSE    => 'perl_5'

 , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
            { type => 'git'
            , url  => 'https://github.com/markov2/perl5-XML-Compile-SOAP-Daemon.git'
            , web  => 'https://github.com/markov2/perl5-XML-Compile-SOAP-Daemon'
            }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/xml-compile-soap-daemon/raw
DISTDIR         = ../public_html/xml-compile-soap-daemon/source
SKIP_LINKS      = XML::LibXML

# for POD
EXTENDSi        = ../XML-Compile:../XML-Compile-SOAP:../XML-Compile-SOAP12:../../perl/XMLTester:../XML-Compile-Cache
FIRST_YEAR      = 2007
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/CPAN/
__POSTAMBLE
