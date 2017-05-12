use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile
  ( NAME	 => 'Tie::Nested'
  , VERSION      => '0.10'
  , PREREQ_PM    =>
    { Test::More  => '0.47'
    , Hash::Case  => '1.01'  # only for the tests
    , Log::Report => '0.26'
    }
  , AUTHOR       => 'Mark Overmeer'
  , ABSTRACT     => 'Ties on nested structures'
  , LICENSE      => 'perl'
  );

sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/tie-nested/raw
DISTDIR         = ../public_html/tie-nested/source
LICENSE         = artistic

# for POD
FIRST_YEAR      = 2010
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/tie-nested

__POSTAMBLE

