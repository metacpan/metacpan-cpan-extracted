# This file is encoded in US-ASCII.
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

# Big5 multibyte structure, verified directly through the runtime API. mb is
# loaded with require (no source filter), so this runs on every perl from
# 5.005_03 up. All multibyte bytes are written with \x escapes so the source
# stays US-ASCII.
#
# Big5 is a two-octet encoding: a lead \x81-\xFE reads one more octet; \x00-\x80
# and \xFF are one-octet units. The Big5 trailing octet range includes the low
# bytes \x40-\x7E, so \x40 ("@") and the notorious \x5C ("\") can sit INSIDE a
# character and must not be seen as boundaries.
#
# Big5 characters:
#   A   US-ASCII single octet   "Z"          (\x5A)
#   C1  two octets              \xA4\x40      (kanji "one"; trailing "@")
#   C2  two octets              \xA4\x5C      (trailing "\" -- Big5 backslash trap)
#   C3  two octets              \xA4\xA4      (kanji "middle")

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
require mb;
use vars qw(@test);

mb::set_script_encoding('big5');

my $A  = "\x5A";         # "Z"
my $C1 = "\xA4\x40";     # 2-octet, trailing "@" (\x40)
my $C2 = "\xA4\x5C";     # 2-octet, trailing "\" (\x5C)
my $C3 = "\xA4\xA4";     # 2-octet
my $s  = $A . $C1 . $C2 . $C3 . $A;  # 1+2+2+2+1 octets, 5 characters

BEGIN { open(GETCFH,">@{[__FILE__]}.getc.tmp") or die $!; binmode GETCFH; print GETCFH "\x5A\xA4\x40\xA4\x5C\xA4\xA4\x5A"; close(GETCFH); }
END   { unlink("@{[__FILE__]}.getc.tmp") }

@test = (

# get/set round trip
    sub { mb::get_script_encoding() eq 'big5' },

# octet vs character count
    sub { CORE::length($s) == 8 },
    sub { mb::length($s)   == 5 },

# substr walks by character, keeping each multibyte char whole
    sub { mb::substr($s, 0, 1) eq $A },
    sub { mb::substr($s, 1, 1) eq $C1 },   # trailing \x40 kept inside the char
    sub { mb::substr($s, 2, 1) eq $C2 },   # trailing \x5C kept inside the char
    sub { mb::substr($s, 3, 1) eq $C3 },
    sub { mb::substr($s, 4, 1) eq $A },
    sub { mb::substr($s, -1, 1) eq $A },
    sub { mb::substr($s, 1, 3) eq ($C1 . $C2 . $C3) },

# index / rindex return character offsets, not octet offsets
    sub { mb::index($s, $C1) == 1 },
    sub { mb::index($s, $C2) == 2 },
    sub { mb::index($s, $C3) == 3 },
    sub { mb::rindex($s, $A) == 4 },
    sub { mb::index($s, $A)  == 0 },

# the ASCII octets buried inside multibyte chars are not findable as chars
    sub { mb::index($s, "\x40") == -1 },
    sub { mb::index($s, "\x5C") == -1 },

# reverse keeps each character whole, only reorders them
    sub { mb::reverse($s) eq ($A . $C3 . $C2 . $C1 . $A) },

# chop removes one whole character from the end
    sub { my $c = $s; my $ch = mb::chop($c);
          ($ch eq $A) and (mb::length($c) == 4) },

# chop a string whose last character has a trailing \x5C
    sub { my $c = $A . $C2; my $ch = mb::chop($c);
          ($ch eq $C2) and (mb::length($c) == 1) and ($c eq $A) },

# the multibyte anchor: /./ (transpiled) steps one character at a time
    sub { my $code = mb::parse(q{my @c = $s =~ /(.)/g; scalar(@c)});
          (eval $code) == 5 },
    sub { my $code = mb::parse(q{my @c = $s =~ /(.)/g; $c[2]});
          (eval $code) eq $C2 },

# US-ASCII class [A-Z] matches only the two real "Z" chars, never bytes buried
# inside the multibyte chars
    sub { my $code = mb::parse(q{my $n = () = $s =~ /([A-Z])/g; $n});
          (eval $code) == 2 },

# getc-style lead dispatch: \x81-\xFE are leads, \x00-\x80 and \xFF single
    sub { ("\x81" =~ /\A [\x81-\xFE] \z/x) ? 1 : 0 },
    sub { ("\x80" =~ /\A [\x81-\xFE] \z/x) ? 0 : 1 },
    sub { ("\xFF" =~ /\A [\x81-\xFE] \z/x) ? 0 : 1 },

# mb::getc reads one whole character at a time from a real filehandle
    sub { open(GETCFH,"@{[__FILE__]}.getc.tmp") or die $!; binmode GETCFH;
          my $c1 = mb::getc(*GETCFH); my $c2 = mb::getc(*GETCFH);
          my $c3 = mb::getc(*GETCFH); my $c4 = mb::getc(*GETCFH);
          my $c5 = mb::getc(*GETCFH); my $c6 = mb::getc(*GETCFH);
          close(GETCFH);
          ($c1 eq $A) and ($c2 eq $C1) and ($c3 eq $C2) and
          ($c4 eq $C3) and ($c5 eq $A) and (not defined $c6) },

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
