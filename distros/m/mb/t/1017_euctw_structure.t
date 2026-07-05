# This file is encoded in US-ASCII.
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

# EUC-TW multibyte structure, verified directly through the runtime API.
# mb is loaded with require (no source filter), so this runs on every perl
# from 5.005_03 up. All multibyte bytes are written with \x escapes so the
# source stays US-ASCII.
#
# EUC-TW characters:
#   A  US-ASCII single octet               "Z"            (\x5A)
#   P  CNS 11643 plane 1, two octets        \xA1\xA1
#   Q  SS2 four octets, plane 2..16         \x8E\xA1\xA1\x41
# Q's final octet is \x41 ("A"); a correct implementation must treat Q as one
# four-octet character and must NOT see that \x41 as a character boundary.

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
require mb;
use vars qw(@test);

mb::set_script_encoding('euctw');

my $A = "\x5A";                 # "Z"
my $P = "\xA1\xA1";             # 2-octet
my $Q = "\x8E\xA1\xA1\x41";     # 4-octet SS2, trailing octet is ASCII "A"
my $s = $A . $P . $Q . $A;      # 1+2+4+1 octets, 4 characters

BEGIN { open(GETCFH,">@{[__FILE__]}.getc.tmp") or die $!; binmode GETCFH; print GETCFH "\x5A\xA1\xA1\x8E\xA1\xA1\x41\x5A"; close(GETCFH); }
END   { unlink("@{[__FILE__]}.getc.tmp") }

@test = (

# octet vs character count
    sub { CORE::length($s) == 8 },
    sub { mb::length($s)   == 4 },

# substr walks by character, keeping each multibyte char whole
    sub { mb::substr($s, 0, 1) eq $A },
    sub { mb::substr($s, 1, 1) eq $P },
    sub { mb::substr($s, 2, 1) eq $Q },   # the 4-octet SS2 char, undivided
    sub { mb::substr($s, 3, 1) eq $A },
    sub { mb::substr($s, -1, 1) eq $A },
    sub { mb::substr($s, 1, 2) eq ($P . $Q) },

# index / rindex return character offsets, not octet offsets
    sub { mb::index($s, $P)  == 1 },
    sub { mb::index($s, $Q)  == 2 },
    sub { mb::rindex($s, $A) == 3 },
    sub { mb::index($s, $A)  == 0 },

# the ASCII octet \x41 sitting inside Q is not findable as a character
    sub { mb::index($s, "\x41") == -1 },

# reverse keeps each character whole, only reorders them
    sub { mb::reverse($s) eq ($A . $Q . $P . $A) },

# chop removes one whole character from the end
    sub { my $c = $s; my $ch = mb::chop($c);
          ($ch eq $A) and (mb::length($c) == 3) and ($c eq ($A . $P . $Q)) },

# chop a string whose last character is the 4-octet SS2 char
    sub { my $c = $A . $P . $Q; my $ch = mb::chop($c);
          ($ch eq $Q) and (mb::length($c) == 2) and ($c eq ($A . $P)) },

# the multibyte anchor: /./ (transpiled) steps one character at a time
    sub { my $code = mb::parse(q{my @c = $s =~ /(.)/g; scalar(@c)});
          (eval $code) == 4 },
    sub { my $code = mb::parse(q{my @c = $s =~ /(.)/g; $c[2]});
          (eval $code) eq $Q },

# US-ASCII class [A-Z] matches only the two real ASCII chars, never the
# \x41 buried inside Q
    sub { my $code = mb::parse(q{my $n = () = $s =~ /([A-Z])/g; $n});
          (eval $code) == 2 },

# getc-style lead dispatch: \x8E implies 4 octets, \xA1-\xFE implies 2
    sub { ("\x8E" =~ /\A [\x8E] \z/x) ? 1 : 0 },

# mb::getc reads one whole character at a time from a real filehandle: the
# plane-1 lead \xA1-\xFE pulls one more octet, the SS2 lead \x8E pulls three
    sub { open(GETCFH,"@{[__FILE__]}.getc.tmp") or die $!; binmode GETCFH;
          my $c1 = mb::getc(*GETCFH); my $c2 = mb::getc(*GETCFH);
          my $c3 = mb::getc(*GETCFH); my $c4 = mb::getc(*GETCFH);
          close(GETCFH);
          ($c1 eq $A) and ($c2 eq $P) and ($c3 eq $Q) and ($c4 eq $A) },

# hyphen ranges in a character class with a 4-octet SS2 endpoint, length-first
# ordering (every 1-octet char < every 2-octet char < every 4-octet char). The
# test character and the range endpoints are built as raw bytes at run time
# (with pack/\x), so this source file stays US-ASCII while mb::parse receives
# real octets -- the same mechanism as t/3030. The endpoints carry no
# metacharacter octet; the SS2 test char's trailing octet is \x5C (backslash),
# which a length-first range must still classify correctly.
    sub { my $t = "\x8E\xA1\xA1\x5C";                              # valid SS2, tail \x5C
          my $lo = pack('H*','00'); my $hi = pack('H*','8EB0FEFF');
          my $code = mb::parse(qq{ \$t =~ /[$lo-$hi]/ });
          (eval $code) ? 1 : 0 },                                 # [ascii..SS2-top] includes it
    sub { my $t = "\x8E\xA1\xA1\x5C";
          my $lo = pack('H*','00'); my $hi = pack('H*','8EA1A100');
          my $code = mb::parse(qq{ \$t =~ /[$lo-$hi]/ });
          (eval $code) ? 0 : 1 },                                 # upper bound below it -> excluded
    sub { my $t = "\x8E\xA1\xA1\x5C";
          my $lo = pack('H*','A1A1'); my $hi = pack('H*','8EB0FEFF');
          my $code = mb::parse(qq{ \$t =~ /[$lo-$hi]/ });
          (eval $code) ? 1 : 0 },                                 # [plane1..SS2] includes all SS2
    sub { my $t = "\xC1\xC1";                                     # a 2-octet plane1 char
          my $lo = pack('H*','8EA1A100'); my $hi = pack('H*','8EB0FEFF');
          my $code = mb::parse(qq{ \$t =~ /[$lo-$hi]/ });
          (eval $code) ? 0 : 1 },                                 # 4-octet-only range excludes 2-octet
    sub { my $t = "\x8E\xB0\xFE\xFF";                             # SS2 max
          my $lo = pack('H*','41'); my $hi = pack('H*','8EB0FEFF');
          my $code = mb::parse(qq{ \$t =~ /[$lo-$hi]/ });
          (eval $code) ? 1 : 0 },                                 # inclusive upper endpoint

# truncated input: a file that ends in the MIDDLE of a multibyte character.
# mb::getc must read the octets that are present, return them, and MUST NOT
# warn "uninitialized value" when the trailing octet(s) hit EOF. The next
# mb::getc then returns undef. Warnings are forced on with local $^W and
# captured with $SIG{__WARN__} so this stays a real guard even under `perl`
# (no -w). $w must stay empty.

# SS2 \x8E four-octet char truncated after 1 of 4 octets
    sub { open(TRUNCFH,">@{[__FILE__]}.trunc.tmp") or die $!;
          binmode TRUNCFH; print TRUNCFH "\x8E"; close(TRUNCFH);
          my $w = ''; local $^W = 1; local $SIG{__WARN__} = sub { $w .= $_[0] };
          open(TRUNCFH,"@{[__FILE__]}.trunc.tmp") or die $!; binmode TRUNCFH;
          my $c1 = mb::getc(*TRUNCFH); my $c2 = mb::getc(*TRUNCFH);
          close(TRUNCFH); unlink("@{[__FILE__]}.trunc.tmp");
          ($c1 eq "\x8E") and (not defined $c2) and ($w eq '') },

# SS2 \x8E four-octet char truncated after 2 of 4 octets
    sub { open(TRUNCFH,">@{[__FILE__]}.trunc.tmp") or die $!;
          binmode TRUNCFH; print TRUNCFH "\x8E\xA1"; close(TRUNCFH);
          my $w = ''; local $^W = 1; local $SIG{__WARN__} = sub { $w .= $_[0] };
          open(TRUNCFH,"@{[__FILE__]}.trunc.tmp") or die $!; binmode TRUNCFH;
          my $c1 = mb::getc(*TRUNCFH); my $c2 = mb::getc(*TRUNCFH);
          close(TRUNCFH); unlink("@{[__FILE__]}.trunc.tmp");
          ($c1 eq "\x8E\xA1") and (not defined $c2) and ($w eq '') },

# SS2 \x8E four-octet char truncated after 3 of 4 octets
    sub { open(TRUNCFH,">@{[__FILE__]}.trunc.tmp") or die $!;
          binmode TRUNCFH; print TRUNCFH "\x8E\xA1\xA1"; close(TRUNCFH);
          my $w = ''; local $^W = 1; local $SIG{__WARN__} = sub { $w .= $_[0] };
          open(TRUNCFH,"@{[__FILE__]}.trunc.tmp") or die $!; binmode TRUNCFH;
          my $c1 = mb::getc(*TRUNCFH); my $c2 = mb::getc(*TRUNCFH);
          close(TRUNCFH); unlink("@{[__FILE__]}.trunc.tmp");
          ($c1 eq "\x8E\xA1\xA1") and (not defined $c2) and ($w eq '') },

# plane-1 2-octet char (\xA1-\xFE lead) truncated after 1 of 2 octets
    sub { open(TRUNCFH,">@{[__FILE__]}.trunc.tmp") or die $!;
          binmode TRUNCFH; print TRUNCFH "\xA1"; close(TRUNCFH);
          my $w = ''; local $^W = 1; local $SIG{__WARN__} = sub { $w .= $_[0] };
          open(TRUNCFH,"@{[__FILE__]}.trunc.tmp") or die $!; binmode TRUNCFH;
          my $c1 = mb::getc(*TRUNCFH); my $c2 = mb::getc(*TRUNCFH);
          close(TRUNCFH); unlink("@{[__FILE__]}.trunc.tmp");
          ($c1 eq "\xA1") and (not defined $c2) and ($w eq '') },

);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
