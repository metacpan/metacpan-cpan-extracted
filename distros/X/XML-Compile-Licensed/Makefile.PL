use ExtUtils::MakeMaker;

use 5.008;

my $version = '0.02';

my $prereq =
   { XML::Compile         => '1.51'
   , File::Spec           => 0
   , File::Basename       => 0
   };

WriteMakefile
 ( NAME	 	 => 'XML::Compile::Licensed'
 , VERSION	 => $version
 , PREREQ_PM => $prereq
 , AUTHOR    => 'Mark Overmeer <markov@cpan.org>'
 , ABSTRACT  => 'restricted XML files'
 , LICENSE   => 'perl_5'

 , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/markov2/perl5-XML-Compile-Licensed.git'
              , web  => 'https://github.com/markov2/perl5-XML-Compile-Licensed'
              }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }

 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

EXTENDS			= ../XML-Compile:../XML-Compile-SOAP:../XML-Compile-SOAP12:../XML-Compile-SOAP-Daemon

# for DIST
RAWDIR          = ../public_html/xml-compile-licensed/raw
DISTDIR         = ../public_html/xml-compile-licensed/source
SKIP_LINKS      = XML::LibXML

# for POD
FIRST_YEAR      = 2016
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/CPAN/
__POSTAMBLE
