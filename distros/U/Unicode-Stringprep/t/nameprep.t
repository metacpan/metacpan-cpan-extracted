use strict;
use utf8;

no warnings 'utf8';

use Test::More;
use Test::NoWarnings;

use Unicode::Stringprep;

our @strprep = (
     [
       "Map to nothing",
       "foo\x{00AD}\x{034F}\x{1806}\x{180B}".
       "bar\x{200B}\x{2060}baz\x{FE00}\x{FE08}".
       "\x{FE0F}\x{FEFF}", "foobarbaz"
     ],
     [
       "Case folding ASCII U+0043 U+0041 U+0046 U+0045",
       "CAFE", "cafe"
     ],
     [
       "Case folding 8bit U+00DF (german sharp s)",
       "\x{00DF}", "ss"
     ],
     [
       "Case folding U+0130 (turkish capital I with dot)",
       "\x{0130}", "i\x{0307}"
     ],
     [
       "Case folding multibyte U+0143 U+037A",
       "\x{0143}\x{037A}", "\x{0144} \x{03B9}"
     ],
     [
       "Case folding U+2121 U+33C6 U+1D7BB",
       "\x{2121}\x{33C6}\x{1D7BB}",
       "telc\x{2215}kg\x{03C3}"
     ],
     [
       "Normalization of U+006a U+030c U+00A0 U+00AA",
       "\x6A\x{030C}\x{00A0}\x{00AA}", "\x{01F0} a"
     ],
     [
       "Case folding U+1FB7 and normalization",
       "\x{1FB7}", "\x{1FB6}\x{03B9}"
     ],
     [
       "Self-reverting case folding U+01F0 and normalization",
       "\x{01F0}", "\x{01F0}"
     ],
     [
       "Self-reverting case folding U+0390 and normalization",
       "\x{0390}", "\x{0390}"
     ],
     [
       "Self-reverting case folding U+03B0 and normalization",
       "\x{03B0}", "\x{03B0}"
     ],
     [
       "Self-reverting case folding U+1E96 and normalization",
       "\x{1E96}", "\x{1E96}"
     ],
     [
       "Self-reverting case folding U+1F56 and normalization",
       "\x{1F56}", "\x{1F56}"
     ],
     [
       "ASCII space character U+0020",
       "\x20", "\x20"
     ],
     [
       "Non-ASCII 8bit space character U+00A0",
       "\x{00A0}", "\x20"
     ],
     [
       "Non-ASCII multibyte space character U+1680",
       "\x{1680}", undef, "Nameprep", 0,
       'STRINGPREP_CONTAINS_PROHIBITED'
     ],
     [
       "Non-ASCII multibyte space character U+2000",
       "\x{2000}", "\x20"
     ],
     [
       "Zero Width Space U+200b",
       "\x{200B}", ''
     ],
     [
       "Non-ASCII multibyte space character U+3000",
       "\x{3000}", "\x20"
     ],
     [
       "ASCII control characters U+0010 U+007F",
       "\x10\x7F", "\x10\x7F"
     ],
     [
       "Non-ASCII 8bit control character U+0085",
       "\x{0085}", undef, "Nameprep", 0,
       'STRINGPREP_CONTAINS_PROHIBITED'
     ],
     [
       "Non-ASCII multibyte control character U+180E",
       "\x{180E}", undef, "Nameprep", 0,
       'STRINGPREP_CONTAINS_PROHIBITED'
     ],
     [
       "Zero Width No-Break Space U+FEFF",
       "\x{FEFF}", ''
     ],
     [
       "Non-ASCII control character U+1D175",
       "\x{1D175}", undef, "Nameprep", 0,
       'STRINGPREP_CONTAINS_PROHIBITED'
     ],
     [
       "Plane 0 private use character U+F123",
       "\x{F123}", undef, "Nameprep", 0,
       'STRINGPREP_CONTAINS_PROHIBITED'
     ],
     [
       "Plane 15 private use character U+F1234",
       "\x{F1234}", undef, "Nameprep", 0,
       'STRINGPREP_CONTAINS_PROHIBITED'
     ],
     [
       "Plane 16 private use character U+10F234",
       "\x{10F234}", undef, "Nameprep", 0,
       'STRINGPREP_CONTAINS_PROHIBITED'
     ],
     [
       "Non-character code point U+8FFFE",
       "\x{8FFFE}", undef, "Nameprep", 0,
       'STRINGPREP_CONTAINS_PROHIBITED'
     ],
     [
       "Non-character code point U+10FFFF",
       "\x{10FFFF}", undef, "Nameprep", 0,
       'STRINGPREP_CONTAINS_PROHIBITED'
     ],
     [
       "Surrogate code U+DF42",
       "\x{DF42}", undef, "Nameprep", 0,
       'STRINGPREP_CONTAINS_PROHIBITED',
       5.008003, "matching surrogate pairs U+D800..DFFF"
     ],
     [
       "Non-plain text character U+FFFD",
       "\x{FFFD}", undef, "Nameprep", 0,
       'STRINGPREP_CONTAINS_PROHIBITED'
     ],
     [
       "Ideographic description character U+2FF5",
       "\x{2FF5}", undef, "Nameprep", 0,
       'STRINGPREP_CONTAINS_PROHIBITED'
     ],
     [
       "Display property character U+0341",
       "\x{0341}", "\x{0301}"
     ],
     [
       "Left-to-right mark U+200E",
       "\x{200E}", "\x{0301}", "Nameprep", 0,
       'STRINGPREP_CONTAINS_PROHIBITED'
     ],
     [
       "Deprecated U+202A",
       "\x{202A}", "\x{0301}", "Nameprep", 0,
       'STRINGPREP_CONTAINS_PROHIBITED'
     ],
     [
       "Language tagging character U+E0001",
       "\x{E0001}", "\x{0301}", "Nameprep", 0,
       'STRINGPREP_CONTAINS_PROHIBITED'
     ],
     [
       "Language tagging character U+E0042",
       "\x{E0042}", undef, "Nameprep", 0,
       'STRINGPREP_CONTAINS_PROHIBITED'
     ],
     [
       "Bidi: RandALCat character U+05BE and LCat characters",
       "foo\x{05BE}bar", undef, "Nameprep", 0,
       'STRINGPREP_BIDI_BOTH_L_AND_RAL'
     ],
     [
       "Bidi: RandALCat character U+FD50 and LCat characters",
       "foo\x{FD50}bar", undef, "Nameprep", 0,
       'STRINGPREP_BIDI_BOTH_L_AND_RAL'
     ],
     [
       "Bidi: RandALCat character U+FB38 and LCat characters",
       "foo\x{FE76}bar", "foo \x{064E}bar"
     ],
     [ "Bidi: RandALCat without trailing RandALCat U+0627 U+0031",
       "\x{0627}\x31", undef, "Nameprep", 0,
       'STRINGPREP_BIDI_LEADTRAIL_NOT_RAL']
     ,
     [
       "Bidi: RandALCat character U+0627 U+0031 U+0628",
       "\x{0627}\x31\x{0628}", "\x{0627}\x31\x{0628}"
     ],
     [
       "Unassigned code point U+E0002",
       "\x{E0002}", "\x{E0002}", "Nameprep", # 'STRINGPREP_NO_UNASSIGNED',
       # 'STRINGPREP_CONTAINS_UNASSIGNED'
     ],
     [
       "Larger test (shrinking)",
       "X\x{00AD}\x{00DF}\x{0130}\x{2121}\x6a\x{030C}\x{00A0}".
       "\x{00AA}\x{03B0}\x{2000}", "xssi\x{0307}tel\x{01F0} a\x{03B0} ",
       "Nameprep"
     ],
     [
       "Larger test (expanding)",
       "X\x{00DF}\x{3316}\x{0130}\x{2121}\x{249F}\x{3300}",
       "xss\x{30AD}\x{30ED}\x{30E1}\x{30FC}\x{30C8}".
       "\x{30EB}i\x{0307}tel\x28d\x29\x{30A2}\x{30D1}".
       "\x{30FC}\x{30C8}"
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

  SKIP: { 
    skip sprintf('%s only works from perl v%d.%d.%d', 
        $min_perl_reason || "test", 
        int($min_perl), int($min_perl*1000)%1000, int($min_perl*1000*1000)%1000,), 1 
      if(($min_perl || 0) > $^V);

    if($rc) { is(eval{nameprep($in)}, undef, $comment); }
       else { is(eval{nameprep($in)} || $@, $out, $comment); }
  }
}

# Test vectors extracted from:
#
#                    Nameprep and IDNA Test Vectors
#                   draft-josefsson-idn-test-vectors

# Copyright (C) The Internet Society (2003). All Rights Reserved.
#
# This document and translations of it may be copied and furnished
# to others, and derivative works that comment on or otherwise
# explain it or assist in its implementation may be prepared,
# copied, published and distributed, in whole or in part, without
# restriction of any kind, provided that the above copyright
# notice and this paragraph are included on all such copies and
# derivative works. However, this document itself may not be
# modified in any way, such as by removing the copyright notice or
# references to the Internet Society or other Internet
# organizations, except as needed for the purpose of developing
# Internet standards in which case the procedures for copyrights
# defined in the Internet Standards process must be followed, or
# as required to translate it into languages other than English.
