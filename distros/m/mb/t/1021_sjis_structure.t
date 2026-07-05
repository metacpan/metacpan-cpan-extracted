# This file is encoded in US-ASCII.
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

# Shift_JIS multibyte structure, verified directly through the runtime API.
# mb is loaded with require (no source filter), so this runs on every perl
# from 5.005_03 up. All multibyte bytes are written with \x escapes so the
# source stays US-ASCII.
#
# Shift_JIS characters:
#   A  US-ASCII single octet               "Z"          (\x5A)
#   S  two octets, lead \x82               \x82\xA0
#   B  two octets, trailing octet "A"      \x82\x41     (\x41 buried inside)
#   D  two octets, trailing octet "\"      \x81\x5C     (DAMEMOJI: 2nd octet \)
#   K  JIS X 0201 katakana, single octet   \xA1         (in \xA1-\xDF)
# The lead octets \x81-\x9F and \xE0-\xFC pull a second octet; the katakana
# octets \xA1-\xDF are one-octet units and are NOT leads. B's trailing \x41 and
# D's trailing \x5C must be kept inside their two-octet characters and must NOT
# be seen as character boundaries.

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
require mb;
use vars qw(@test);

mb::set_script_encoding('sjis');

my $A = "\x5A";         # "Z"
my $S = "\x82\xA0";     # 2-octet, lead \x82
my $B = "\x82\x41";     # 2-octet, trailing octet "A" (\x41)
my $D = "\x81\x5C";     # 2-octet, trailing octet "\" (\x5C)
my $s = $A . $S . $B . $D . $A;  # 1+2+2+2+1 octets, 5 characters

BEGIN { open(GETCFH,">@{[__FILE__]}.getc.tmp") or die $!; binmode GETCFH; print GETCFH "\x5A\x82\xA0\x82\x41\x81\x5C\x5A"; close(GETCFH); }
END   { unlink("@{[__FILE__]}.getc.tmp") }

@test = (

# get/set round trip
    sub { mb::get_script_encoding() eq 'sjis' },

# octet vs character count
    sub { CORE::length($s) == 8 },
    sub { mb::length($s)   == 5 },

# substr walks by character, keeping each multibyte char whole
    sub { mb::substr($s, 0, 1) eq $A },
    sub { mb::substr($s, 1, 1) eq $S },
    sub { mb::substr($s, 2, 1) eq $B },   # trailing \x41 kept inside the char
    sub { mb::substr($s, 3, 1) eq $D },   # trailing \x5C kept inside the char
    sub { mb::substr($s, 4, 1) eq $A },
    sub { mb::substr($s, -1, 1) eq $A },
    sub { mb::substr($s, 1, 2) eq ($S . $B) },

# index / rindex return character offsets, not octet offsets
    sub { mb::index($s, $S)  == 1 },
    sub { mb::index($s, $B)  == 2 },
    sub { mb::index($s, $D)  == 3 },
    sub { mb::rindex($s, $A) == 4 },
    sub { mb::index($s, $A)  == 0 },

# the ASCII octet \x41 sitting inside B is not findable as a character
    sub { mb::index($s, "\x41") == -1 },

# the \x5C octet sitting inside D is not findable as a character
    sub { mb::index($s, "\x5C") == -1 },

# reverse keeps each character whole, only reorders them
    sub { mb::reverse($s) eq ($A . $D . $B . $S . $A) },

# chop removes one whole character from the end
    sub { my $c = $s; my $ch = mb::chop($c);
          ($ch eq $A) and (mb::length($c) == 4) },

# chop a string whose last character has a trailing \x5C
    sub { my $c = $A . $D; my $ch = mb::chop($c);
          ($ch eq $D) and (mb::length($c) == 1) and ($c eq $A) },

# the multibyte anchor: /./ (transpiled) steps one character at a time
    sub { my $code = mb::parse(q{my @c = $s =~ /(.)/g; scalar(@c)});
          (eval $code) == 5 },
    sub { my $code = mb::parse(q{my @c = $s =~ /(.)/g; $c[2]});
          (eval $code) eq $B },

# US-ASCII class [A-Z] matches only the two real "Z" chars, never the \x41
# ("A") buried inside B
    sub { my $code = mb::parse(q{my $n = () = $s =~ /([A-Z])/g; $n});
          (eval $code) == 2 },

# getc-style lead dispatch: \x81-\x9F\xE0-\xFC are leads, others single
    sub { ("\x82" =~ /\A [\x81-\x9F\xE0-\xFC] \z/x) ? 1 : 0 },
    sub { ("\xA1" =~ /\A [\x81-\x9F\xE0-\xFC] \z/x) ? 0 : 1 },  # katakana not a lead

# mb::getc reads one whole character at a time from a real filehandle
    sub { open(GETCFH,"@{[__FILE__]}.getc.tmp") or die $!; binmode GETCFH;
          my $c1 = mb::getc(*GETCFH); my $c2 = mb::getc(*GETCFH);
          my $c3 = mb::getc(*GETCFH); my $c4 = mb::getc(*GETCFH);
          my $c5 = mb::getc(*GETCFH); my $c6 = mb::getc(*GETCFH);
          close(GETCFH);
          ($c1 eq $A) and ($c2 eq $S) and ($c3 eq $B) and
          ($c4 eq $D) and ($c5 eq $A) and (not defined $c6) },

# truncated input: a file that ends in the MIDDLE of a 2-octet character.
# mb::getc must read the single lead octet that is present, return it, and MUST
# NOT warn "uninitialized value" when the trailing octet hits EOF. The next
# mb::getc then returns undef. Warnings are forced on with local $^W and
# captured with $SIG{__WARN__} so this stays a real guard even under `perl`
# (no -w). $w must stay empty.
    sub { open(TRUNCFH,">@{[__FILE__]}.trunc.tmp") or die $!;
          binmode TRUNCFH; print TRUNCFH "\x82"; close(TRUNCFH);
          my $w = ''; local $^W = 1; local $SIG{__WARN__} = sub { $w .= $_[0] };
          open(TRUNCFH,"@{[__FILE__]}.trunc.tmp") or die $!; binmode TRUNCFH;
          my $c1 = mb::getc(*TRUNCFH); my $c2 = mb::getc(*TRUNCFH);
          close(TRUNCFH); unlink("@{[__FILE__]}.trunc.tmp");
          ($c1 eq "\x82") and (not defined $c2) and ($w eq '') },

# strict validity: the well-formed sample is valid
    sub { mb::valid($s) == 1 },
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
