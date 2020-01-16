use ExtUtils::MakeMaker;

use 5.010;

WriteMakefile
 ( NAME	 	=> 'XML::Compile::RPC'
 , VERSION	=> '0.20'
 , PREREQ_PM    =>
   { XML::Compile              => 1.08
   , XML::Compile::Cache       => 0.92
   , XML::Compile::Tester      => 0.05
   , Log::Report               => 0.28
   , Time::HiRes               => 0
   , LWP::UserAgent            => 0
   , File::Glob                => 0
   , File::Basename            => 0

   , Test::More                => 0.54
   }

 , EXE_FILES    => []
 , ABSTRACT     => 'XML-RPC client via XML::Compile'
 , AUTHOR       => 'Mark Overmeer <markov@cpan.org>'
 , LICENSE      => 'perl_5'

 , META_MERGE   =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/markov2/perl5-XML-Compile-RPC.git'
              , web  => 'https://github.com/markov2/perl5-XML-Compile-RPC'
              }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
EXTENDS         = ../XML-Compile:../XML-Compile-Cache:../XML-ExistDB
RAWDIR          = ../public_html/xml-compile-rpc/raw
DISTDIR         = ../public_html/xml-compile-rpc/source
SKIP_LINKSi     = XML::LibXML

# for POD
FIRST_YEAR      = 2009
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/xml-compile/
__POSTAMBLE
