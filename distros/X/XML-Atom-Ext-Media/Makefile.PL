
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'XML-Atom-Ext-Media',
  NAME      => 'XML::Atom::Ext::Media',
  AUTHOR    => 'Andreas\ Marienborg\ \<andremar\@cpan\.org\>',
  ABSTRACT  => 'An\ XML\:\:Atom\ extenstion\ for\ the\ yahoo\ Media\ RSS\ extension',
  VERSION   => '0.092840',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "base" => '0',
    "XML::Atom::Feed" => '0',
    "Test::More" => '0.92',
    "ok" => '0',
  },
  test => {TESTS => 't/*.t'}
);

