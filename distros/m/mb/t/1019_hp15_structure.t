# This file is encoded in US-ASCII.
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

# HP-15 multibyte structure, verified directly through the runtime API.
# mb is loaded with require (no source filter), so this runs on every perl
# from 5.005_03 up. All multibyte bytes are written with \x escapes so the
# source stays US-ASCII.
#
# HP-15 characters (verified against the legacy Ehp15 %range_tr):
#   A  US-ASCII single octet                 "Z"          (\x5A)
#   K  JIS X 0201 katakana, single octet     \xB1         (in \xA1-\xDF)
#   F  the single octet \xFF                 \xFF
#   P  two octets, low lead 0x80             \x80\x41     (trailing octet "A")
#   R  two octets, lead 0x80 trail 0x5C      \x80\x5C     (DAMEMOJI: 2nd octet \)
#   T  two octets, top lead 0xFE             \xFE\xFF
#   U  two octets, lead 0xA0 (a lead, NOT    \xA0\x21
#      a single octet as it would be in sjis)
# 0x80 and 0xA0 are LEAD octets in HP-15 (single octets in sjis); a correct
# implementation must read the following octet and must NOT split there. The
# single octets \xA1-\xDF and \xFF are one-octet units and are NOT leads.

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
require mb;
use vars qw(@test);

mb::set_script_encoding('hp15');

my $A = "\x5A";         # "Z"
my $K = "\xB1";         # katakana, single octet
my $F = "\xFF";         # single octet
my $P = "\x80\x41";     # 2-octet, low lead 0x80, trailing "A"
my $R = "\x80\x5C";     # 2-octet, trailing octet is "\" (\x5C)
my $T = "\xFE\xFF";     # 2-octet, top lead 0xFE
my $U = "\xA0\x21";     # 2-octet, lead 0xA0 (top of first lead range)
my $s = $A . $K . $F . $P . $R . $T . $U;  # 1+1+1+2+2+2+2 octets, 7 characters

BEGIN { open(GETCFH,">@{[__FILE__]}.getc.tmp") or die $!; binmode GETCFH; print GETCFH "\x5A\xB1\xFF\x80\x41\x80\x5C\xFE\xFF\xA0\x21"; close(GETCFH); }
END   { unlink("@{[__FILE__]}.getc.tmp") }

@test = (

# octet vs character count
    sub { CORE::length($s) == 11 },
    sub { mb::length($s)   == 7  },

# substr walks by character, keeping each multibyte char whole
    sub { mb::substr($s, 0, 1) eq $A },
    sub { mb::substr($s, 1, 1) eq $K },   # katakana stays a single octet
    sub { mb::substr($s, 2, 1) eq $F },   # \xFF stays a single octet
    sub { mb::substr($s, 3, 1) eq $P },   # lead 0x80 reads two octets
    sub { mb::substr($s, 4, 1) eq $R },   # trailing \x5C kept inside the char
    sub { mb::substr($s, 5, 1) eq $T },   # lead 0xFE reads two octets
    sub { mb::substr($s, 6, 1) eq $U },   # lead 0xA0 reads two octets
    sub { mb::substr($s, -1, 1) eq $U },
    sub { mb::substr($s, 3, 2) eq ($P . $R) },

# index / rindex return character offsets, not octet offsets
    sub { mb::index($s, $P)  == 3 },
    sub { mb::index($s, $R)  == 4 },
    sub { mb::index($s, $T)  == 5 },
    sub { mb::index($s, $K)  == 1 },
    sub { mb::rindex($s, $A) == 0 },

# the ASCII octet \x41 sitting inside P is not findable as a character
    sub { mb::index($s, "\x41") == -1 },

# the \x5C octet sitting inside R is not findable as a character
    sub { mb::index($s, "\x5C") == -1 },

# reverse keeps each character whole, only reorders them
    sub { mb::reverse($s) eq ($U . $T . $R . $P . $F . $K . $A) },

# chop removes one whole character (the 2-octet $U) from the end
    sub { my $c = $s; my $ch = mb::chop($c);
          ($ch eq $U) and (mb::length($c) == 6) },

# chop a string whose last character has a trailing \x5C
    sub { my $c = $A . $R; my $ch = mb::chop($c);
          ($ch eq $R) and (mb::length($c) == 1) and ($c eq $A) },

# the multibyte anchor: /./ (transpiled) steps one character at a time
    sub { my $code = mb::parse(q{my @c = $s =~ /(.)/g; scalar(@c)});
          (eval $code) == 7 },
    sub { my $code = mb::parse(q{my @c = $s =~ /(.)/g; $c[3]});
          (eval $code) eq $P },
    sub { my $code = mb::parse(q{my @c = $s =~ /(.)/g; $c[4]});
          (eval $code) eq $R },

# US-ASCII class [A-Z] matches only the real ASCII char, never the \x41
# buried inside P
    sub { my $code = mb::parse(q{my $n = () = $s =~ /([A-Z])/g; $n});
          (eval $code) == 1 },

# getc-style lead dispatch: \x80-\xA0 and \xE0-\xFE are leads, others single
    sub { ("\x80" =~ /\A [\x80-\xA0\xE0-\xFE] \z/x) ? 1 : 0 },
    sub { ("\xA0" =~ /\A [\x80-\xA0\xE0-\xFE] \z/x) ? 1 : 0 },
    sub { ("\xFE" =~ /\A [\x80-\xA0\xE0-\xFE] \z/x) ? 1 : 0 },
    sub { ("\xB1" =~ /\A [\x80-\xA0\xE0-\xFE] \z/x) ? 0 : 1 },  # katakana not a lead
    sub { ("\xFF" =~ /\A [\x80-\xA0\xE0-\xFE] \z/x) ? 0 : 1 },  # \xFF not a lead

# mb::getc reads one whole character at a time from a real filehandle; the
# leads 0x80/0xA0/0xFE must pull a second octet, the katakana and \xFF octets
# must not
    sub { open(GETCFH,"@{[__FILE__]}.getc.tmp") or die $!; binmode GETCFH;
          my $c1 = mb::getc(*GETCFH); my $c2 = mb::getc(*GETCFH);
          my $c3 = mb::getc(*GETCFH); my $c4 = mb::getc(*GETCFH);
          my $c5 = mb::getc(*GETCFH); my $c6 = mb::getc(*GETCFH);
          my $c7 = mb::getc(*GETCFH); my $c8 = mb::getc(*GETCFH);
          close(GETCFH);
          ($c1 eq $A) and ($c2 eq $K) and ($c3 eq $F) and ($c4 eq $P) and
          ($c5 eq $R) and ($c6 eq $T) and ($c7 eq $U) and (not defined $c8) },

# truncated input: a file that ends in the MIDDLE of a 2-octet character.
# mb::getc must read the single lead octet that is present, return it, and
# MUST NOT warn "uninitialized value" when the trailing octet hits EOF. The
# next mb::getc then returns undef. Warnings are forced on with local $^W and
# captured with $SIG{__WARN__} so this stays a real guard even under `perl`
# (no -w). $w must stay empty. One subtest per lead class: 0x80 (low lead),
# 0xA0 (top of first lead range), 0xFE (top lead).

    sub { open(TRUNCFH,">@{[__FILE__]}.trunc.tmp") or die $!;
          binmode TRUNCFH; print TRUNCFH "\x80"; close(TRUNCFH);
          my $w = ''; local $^W = 1; local $SIG{__WARN__} = sub { $w .= $_[0] };
          open(TRUNCFH,"@{[__FILE__]}.trunc.tmp") or die $!; binmode TRUNCFH;
          my $c1 = mb::getc(*TRUNCFH); my $c2 = mb::getc(*TRUNCFH);
          close(TRUNCFH); unlink("@{[__FILE__]}.trunc.tmp");
          ($c1 eq "\x80") and (not defined $c2) and ($w eq '') },

    sub { open(TRUNCFH,">@{[__FILE__]}.trunc.tmp") or die $!;
          binmode TRUNCFH; print TRUNCFH "\xA0"; close(TRUNCFH);
          my $w = ''; local $^W = 1; local $SIG{__WARN__} = sub { $w .= $_[0] };
          open(TRUNCFH,"@{[__FILE__]}.trunc.tmp") or die $!; binmode TRUNCFH;
          my $c1 = mb::getc(*TRUNCFH); my $c2 = mb::getc(*TRUNCFH);
          close(TRUNCFH); unlink("@{[__FILE__]}.trunc.tmp");
          ($c1 eq "\xA0") and (not defined $c2) and ($w eq '') },

    sub { open(TRUNCFH,">@{[__FILE__]}.trunc.tmp") or die $!;
          binmode TRUNCFH; print TRUNCFH "\xFE"; close(TRUNCFH);
          my $w = ''; local $^W = 1; local $SIG{__WARN__} = sub { $w .= $_[0] };
          open(TRUNCFH,"@{[__FILE__]}.trunc.tmp") or die $!; binmode TRUNCFH;
          my $c1 = mb::getc(*TRUNCFH); my $c2 = mb::getc(*TRUNCFH);
          close(TRUNCFH); unlink("@{[__FILE__]}.trunc.tmp");
          ($c1 eq "\xFE") and (not defined $c2) and ($w eq '') },

);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
