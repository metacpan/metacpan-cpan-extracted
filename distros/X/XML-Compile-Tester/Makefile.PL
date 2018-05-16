use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile
 ( NAME      => 'XML::Compile::Tester'
 , VERSION   => '0.91'
 , PREREQ_PM =>
   { Log::Report => 0.17
   , Test::More  => 0.54
   , Test::Deep  => 0.095
   }
 , AUTHOR     => 'Mark Overmeer <markov@cpan.org>'
 , ABSTRACT   => 'support XML::Compile related regression testing'
 , LICENSE    => 'perl_5'

 , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
            { type => 'git'
            , url  => 'https://github.com/markov2/perl5-XML-Compile-Tester.git'
            , web  => 'https://github.com/markov2/perl5-XML-Compile-Tester'
            }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/xml-compile-tester/raw
DISTDIR         = ../public_html/xml-compile-tester/source
SKIP_LINKS      = XML::LibXML

# for POD
FIRST_YEAR      = 2008
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/CPAN/
__POSTAMBLE
