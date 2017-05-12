use strict;
use bytes; # !!!

# no warnings 'utf8';

use Test::More;
use Test::NoWarnings;

use Unicode::Stringprep;

our @strprep = (
     [
       "Map to nothing",
       "foo\xADbar", "foobar"
     ],
     [
       "Case folding ASCII U+0043 U+0041 U+0046 U+0045",
       "CAFE", "cafe"
     ],
     [
       "Case folding 8bit U+00DF (german sharp s)",
       "ß", "ss"
     ],
     [
       "Normalization of U+00A0 U+00AA",
       " \xAA", " a"
     ],
     [
       "ASCII space character U+0020",
       "\x20", "\x20"
     ],
     [
       "Non-ASCII 8bit space character U+00A0",
       " ", "\x20"
     ],
     [
       "ASCII control characters U+0010 U+007F",
       "\x10\x7F", "\x10\x7F"
     ],
     [
       "Non-ASCII 8bit control character U+0085",
       "\x85", undef, "Nameprep", 0,
       'STRINGPREP_CONTAINS_PROHIBITED'
     ],
   );

plan tests => ($#strprep+1) + 1;

*nameprep = Unicode::Stringprep->new(
  3.2,
  [ 
    \@Unicode::Stringprep::Mapping::B1, 
    \@Unicode::Stringprep::Mapping::B2 
  ],
  'KC',
  [
    \@Unicode::Stringprep::Prohibited::C12,
    \@Unicode::Stringprep::Prohibited::C22,
    \@Unicode::Stringprep::Prohibited::C3,
    \@Unicode::Stringprep::Prohibited::C4,
    \@Unicode::Stringprep::Prohibited::C5,
    \@Unicode::Stringprep::Prohibited::C6,
    \@Unicode::Stringprep::Prohibited::C7,
    \@Unicode::Stringprep::Prohibited::C8,
    \@Unicode::Stringprep::Prohibited::C9
  ],
  1,
);

foreach my $test (@strprep) 
{
  my ($comment,$in,$out,$profile,$flags,$rc, $min_perl, $min_perl_reason) = @{$test};

  if($rc) { is(eval{nameprep($in)}, undef, $comment); }
     else { is(eval{nameprep($in)} || $@, $out, $comment); }
}
