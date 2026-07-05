# This file is encoded in US-ASCII.
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

# EUC-JP multibyte structure, verified directly through the runtime API. mb is
# loaded with require (no source filter), so this runs on every perl from
# 5.005_03 up. All multibyte bytes are written with \x escapes so the source
# stays US-ASCII.
#
# In mb's model EUC-JP is the two-octet JIS X 0208 plane: a lead \xA1-\xFE reads
# one more octet. The single octets \x00-\xA0 and \xFF (including SS2 \x8E and
# SS3 \x8F) are NOT leads here. A real EUC-JP trailing octet is itself \xA1-\xFE,
# so a well-formed EUC-JP multibyte character never contains a US-ASCII octet.
#
# EUC-JP characters:
#   A   US-ASCII single octet   "Z"          (\x5A)
#   H1  two octets              \xA4\xA2      (hiragana A)
#   H2  two octets              \xA4\xA4      (hiragana I)
#   K   two octets              \xB0\xA1      (kanji)

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
require mb;
use vars qw(@test);

mb::set_script_encoding('eucjp');

my $A  = "\x5A";         # "Z"
my $H1 = "\xA4\xA2";     # 2-octet, hiragana A
my $H2 = "\xA4\xA4";     # 2-octet, hiragana I
my $K  = "\xB0\xA1";     # 2-octet, kanji
my $s  = $A . $H1 . $H2 . $K . $A;  # 1+2+2+2+1 octets, 5 characters

BEGIN { open(GETCFH,">@{[__FILE__]}.getc.tmp") or die $!; binmode GETCFH; print GETCFH "\x5A\xA4\xA2\xA4\xA4\xB0\xA1\x5A"; close(GETCFH); }
END   { unlink("@{[__FILE__]}.getc.tmp") }

@test = (

# get/set round trip
    sub { mb::get_script_encoding() eq 'eucjp' },

# octet vs character count
    sub { CORE::length($s) == 8 },
    sub { mb::length($s)   == 5 },

# substr walks by character, keeping each multibyte char whole
    sub { mb::substr($s, 0, 1) eq $A },
    sub { mb::substr($s, 1, 1) eq $H1 },
    sub { mb::substr($s, 2, 1) eq $H2 },
    sub { mb::substr($s, 3, 1) eq $K },
    sub { mb::substr($s, 4, 1) eq $A },
    sub { mb::substr($s, -1, 1) eq $A },
    sub { mb::substr($s, 1, 3) eq ($H1 . $H2 . $K) },

# index / rindex return character offsets, not octet offsets
    sub { mb::index($s, $H1) == 1 },
    sub { mb::index($s, $H2) == 2 },
    sub { mb::index($s, $K)  == 3 },
    sub { mb::rindex($s, $A) == 4 },
    sub { mb::index($s, $A)  == 0 },

# reverse keeps each character whole, only reorders them
    sub { mb::reverse($s) eq ($A . $K . $H2 . $H1 . $A) },

# chop removes one whole character from the end
    sub { my $c = $s; my $ch = mb::chop($c);
          ($ch eq $A) and (mb::length($c) == 4) },

# chop a string whose last character is a 2-octet kanji
    sub { my $c = $A . $K; my $ch = mb::chop($c);
          ($ch eq $K) and (mb::length($c) == 1) and ($c eq $A) },

# the multibyte anchor: /./ (transpiled) steps one character at a time
    sub { my $code = mb::parse(q{my @c = $s =~ /(.)/g; scalar(@c)});
          (eval $code) == 5 },
    sub { my $code = mb::parse(q{my @c = $s =~ /(.)/g; $c[3]});
          (eval $code) eq $K },

# US-ASCII class [A-Z] matches only the two real "Z" chars (a well-formed
# EUC-JP multibyte char has no US-ASCII octet buried inside)
    sub { my $code = mb::parse(q{my $n = () = $s =~ /([A-Z])/g; $n});
          (eval $code) == 2 },

# getc-style lead dispatch: \xA1-\xFE are leads, others (incl. SS2 \x8E) single
    sub { ("\xA1" =~ /\A [\xA1-\xFE] \z/x) ? 1 : 0 },
    sub { ("\xFE" =~ /\A [\xA1-\xFE] \z/x) ? 1 : 0 },
    sub { ("\x8E" =~ /\A [\xA1-\xFE] \z/x) ? 0 : 1 },  # SS2 not a lead in this model
    sub { ("\xA0" =~ /\A [\xA1-\xFE] \z/x) ? 0 : 1 },

# mb::getc reads one whole character at a time from a real filehandle
    sub { open(GETCFH,"@{[__FILE__]}.getc.tmp") or die $!; binmode GETCFH;
          my $c1 = mb::getc(*GETCFH); my $c2 = mb::getc(*GETCFH);
          my $c3 = mb::getc(*GETCFH); my $c4 = mb::getc(*GETCFH);
          my $c5 = mb::getc(*GETCFH); my $c6 = mb::getc(*GETCFH);
          close(GETCFH);
          ($c1 eq $A) and ($c2 eq $H1) and ($c3 eq $H2) and
          ($c4 eq $K) and ($c5 eq $A) and (not defined $c6) },

# truncated input: a file that ends in the MIDDLE of a 2-octet character.
# mb::getc must read the single lead octet that is present, return it, and MUST
# NOT warn "uninitialized value" when the trailing octet hits EOF. The next
# mb::getc then returns undef. Warnings are forced on with local $^W and
# captured with $SIG{__WARN__} so this stays a real guard even under `perl`
# (no -w). $w must stay empty.
    sub { open(TRUNCFH,">@{[__FILE__]}.trunc.tmp") or die $!;
          binmode TRUNCFH; print TRUNCFH "\xA4"; close(TRUNCFH);
          my $w = ''; local $^W = 1; local $SIG{__WARN__} = sub { $w .= $_[0] };
          open(TRUNCFH,"@{[__FILE__]}.trunc.tmp") or die $!; binmode TRUNCFH;
          my $c1 = mb::getc(*TRUNCFH); my $c2 = mb::getc(*TRUNCFH);
          close(TRUNCFH); unlink("@{[__FILE__]}.trunc.tmp");
          ($c1 eq "\xA4") and (not defined $c2) and ($w eq '') },

# strict validity: the well-formed sample is valid
    sub { mb::valid($s) == 1 },
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
