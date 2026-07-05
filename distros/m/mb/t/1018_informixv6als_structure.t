# This file is encoded in US-ASCII.
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

# INFORMIX V6 ALS multibyte structure, verified directly through the runtime
# API. mb is loaded with require (no source filter), so this runs on every
# perl from 5.005_03 up. All multibyte bytes are written with \x escapes so
# the source stays US-ASCII.
#
# INFORMIX V6 ALS characters:
#   A  US-ASCII single octet               "Z"            (\x5A)
#   S  Shift_JIS-compatible two octets      \x82\xA0       (sjis core, == sjis)
#   T  \xFD three-octet user-defined plane  \xFD\xA1\x41
# T's final octet is \x41 ("A"); a correct implementation must treat T as one
# three-octet character and must NOT see that \x41 as a character boundary.
# A bare \xFD not followed by \xA1-\xFE is a one-octet unit, so the codepoint
# walk tries the three-octet form first and falls back to a single octet.

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
require mb;
use vars qw(@test);

mb::set_script_encoding('informixv6als');

my $A = "\x5A";             # "Z"
my $S = "\x82\xA0";         # 2-octet, identical to sjis
my $T = "\xFD\xA1\x41";     # 3-octet \xFD plane, trailing octet is ASCII "A"
my $s = $A . $S . $T . $A;  # 1+2+3+1 octets, 4 characters

BEGIN { open(GETCFH,">@{[__FILE__]}.getc.tmp") or die $!; binmode GETCFH; print GETCFH "\x5A\x82\xA0\xFD\xA1\x41\x5A"; close(GETCFH); }
END   { unlink("@{[__FILE__]}.getc.tmp") }

@test = (

# get/set round trip
    sub { mb::get_script_encoding() eq 'informixv6als' },

# octet vs character count
    sub { CORE::length($s) == 7 },
    sub { mb::length($s)   == 4 },

# substr walks by character, keeping each multibyte char whole
    sub { mb::substr($s, 0, 1) eq $A },
    sub { mb::substr($s, 1, 1) eq $S },
    sub { mb::substr($s, 2, 1) eq $T },   # the 3-octet \xFD char, undivided
    sub { mb::substr($s, 3, 1) eq $A },
    sub { mb::substr($s, -1, 1) eq $A },
    sub { mb::substr($s, 1, 2) eq ($S . $T) },

# index / rindex return character offsets, not octet offsets
    sub { mb::index($s, $S)  == 1 },
    sub { mb::index($s, $T)  == 2 },
    sub { mb::rindex($s, $A) == 3 },
    sub { mb::index($s, $A)  == 0 },

# the ASCII octet \x41 sitting inside T is not findable as a character
    sub { mb::index($s, "\x41") == -1 },

# reverse keeps each character whole, only reorders them
    sub { mb::reverse($s) eq ($A . $T . $S . $A) },

# chop removes one whole character from the end
    sub { my $c = $s; my $ch = mb::chop($c);
          ($ch eq $A) and (mb::length($c) == 3) and ($c eq ($A . $S . $T)) },

# chop a string whose last character is the 3-octet \xFD char
    sub { my $c = $A . $S . $T; my $ch = mb::chop($c);
          ($ch eq $T) and (mb::length($c) == 2) and ($c eq ($A . $S)) },

# a bare \xFD not followed by \xA1-\xFE is one octet, the next byte is its own
# character (here \x41 "A" is then a US-ASCII char)
    sub { mb::length("\xFD\x41")    == 2 },
    sub { mb::substr("\xFD\x41",1,1) eq "\x41" },
# \xFD followed by \xA1-\xFE consumes three octets as one character
    sub { mb::length("\xFD\xA1\x41") == 1 },

# the multibyte anchor: /./ (transpiled) steps one character at a time
    sub { my $code = mb::parse(q{my @c = $s =~ /(.)/g; scalar(@c)});
          (eval $code) == 4 },
    sub { my $code = mb::parse(q{my @c = $s =~ /(.)/g; $c[2]});
          (eval $code) eq $T },

# US-ASCII class [A-Z] matches only the two real "Z" chars, never the \x41
# ("A") buried inside T
    sub { my $code = mb::parse(q{my $n = () = $s =~ /([A-Z])/g; $n});
          (eval $code) == 2 },

# getc-style lead dispatch: \xFD implies 3 octets, \x81-\x9F\xE0-\xFC implies 2
    sub { ("\xFD" =~ /\A [\xFD] \z/x) ? 1 : 0 },
    sub { ("\x82" =~ /\A [\x81-\x9F\xE0-\xFC] \z/x) ? 1 : 0 },

# mb::getc reads one whole character at a time from a real filehandle: the
# sjis-core lead pulls one more octet, the \xFD lead pulls two more
    sub { open(GETCFH,"@{[__FILE__]}.getc.tmp") or die $!; binmode GETCFH;
          my $c1 = mb::getc(*GETCFH); my $c2 = mb::getc(*GETCFH);
          my $c3 = mb::getc(*GETCFH); my $c4 = mb::getc(*GETCFH);
          close(GETCFH);
          ($c1 eq $A) and ($c2 eq $S) and ($c3 eq $T) and ($c4 eq $A) },

# truncated input: a file that ends in the MIDDLE of a multibyte character.
# mb::getc must read the octets that are present, return them, and MUST NOT
# warn "uninitialized value" when the trailing octet(s) hit EOF. The next
# mb::getc then returns undef. Warnings are forced on with local $^W and
# captured with $SIG{__WARN__} so this stays a real guard even under `perl`
# (no -w). $w must stay empty.

# \xFD plane truncated after 1 of 3 octets
    sub { open(TRUNCFH,">@{[__FILE__]}.trunc.tmp") or die $!;
          binmode TRUNCFH; print TRUNCFH "\xFD"; close(TRUNCFH);
          my $w = ''; local $^W = 1; local $SIG{__WARN__} = sub { $w .= $_[0] };
          open(TRUNCFH,"@{[__FILE__]}.trunc.tmp") or die $!; binmode TRUNCFH;
          my $c1 = mb::getc(*TRUNCFH); my $c2 = mb::getc(*TRUNCFH);
          close(TRUNCFH); unlink("@{[__FILE__]}.trunc.tmp");
          ($c1 eq "\xFD") and (not defined $c2) and ($w eq '') },

# \xFD plane truncated after 2 of 3 octets
    sub { open(TRUNCFH,">@{[__FILE__]}.trunc.tmp") or die $!;
          binmode TRUNCFH; print TRUNCFH "\xFD\xA1"; close(TRUNCFH);
          my $w = ''; local $^W = 1; local $SIG{__WARN__} = sub { $w .= $_[0] };
          open(TRUNCFH,"@{[__FILE__]}.trunc.tmp") or die $!; binmode TRUNCFH;
          my $c1 = mb::getc(*TRUNCFH); my $c2 = mb::getc(*TRUNCFH);
          close(TRUNCFH); unlink("@{[__FILE__]}.trunc.tmp");
          ($c1 eq "\xFD\xA1") and (not defined $c2) and ($w eq '') },

# sjis-core 2-octet lead truncated after 1 of 2 octets
    sub { open(TRUNCFH,">@{[__FILE__]}.trunc.tmp") or die $!;
          binmode TRUNCFH; print TRUNCFH "\x82"; close(TRUNCFH);
          my $w = ''; local $^W = 1; local $SIG{__WARN__} = sub { $w .= $_[0] };
          open(TRUNCFH,"@{[__FILE__]}.trunc.tmp") or die $!; binmode TRUNCFH;
          my $c1 = mb::getc(*TRUNCFH); my $c2 = mb::getc(*TRUNCFH);
          close(TRUNCFH); unlink("@{[__FILE__]}.trunc.tmp");
          ($c1 eq "\x82") and (not defined $c2) and ($w eq '') },

# strict validity: the well-formed sample is valid; the 2-octet core matches
# sjis exactly
    sub { mb::valid($A . $S . $T) == 1 },
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
