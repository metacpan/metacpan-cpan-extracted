# This file is encoded in US-ASCII.
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

# UTF-8 multibyte structure, verified directly through the runtime API. mb is
# loaded with require (no source filter), so this runs on every perl from
# 5.005_03 up. All multibyte bytes are written with \x escapes so the source
# stays US-ASCII.
#
# rfc2279, utf8 and wtf8 share the SAME getc lead dispatch used here: a lead
# \xC2-\xDF reads one more octet (2 total), \xE0-\xEF reads two more (3 total),
# \xF0-\xF4 reads three more (4 total). Continuation octets are \x80-\xBF, so a
# UTF-8 multibyte character never contains a US-ASCII octet.
#
# UTF-8 characters:
#   A   US-ASCII single octet   "Z"                (\x5A)
#   U2  two octets              \xC2\xA9           (U+00A9 (C))
#   U3  three octets            \xE2\x82\xAC       (U+20AC EURO SIGN)
#   U4  four octets             \xF0\x9F\x98\x80   (U+1F600 emoji)

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
require mb;
use vars qw(@test);

mb::set_script_encoding('utf8');

my $A  = "\x5A";                 # "Z"
my $U2 = "\xC2\xA9";             # 2-octet
my $U3 = "\xE2\x82\xAC";         # 3-octet
my $U4 = "\xF0\x9F\x98\x80";     # 4-octet
my $s  = $A . $U2 . $U3 . $U4 . $A;  # 1+2+3+4+1 octets, 5 characters

BEGIN { open(GETCFH,">@{[__FILE__]}.getc.tmp") or die $!; binmode GETCFH; print GETCFH "\x5A\xC2\xA9\xE2\x82\xAC\xF0\x9F\x98\x80\x5A"; close(GETCFH); }
END   { unlink("@{[__FILE__]}.getc.tmp") }

@test = (

# get/set round trip
    sub { mb::get_script_encoding() eq 'utf8' },

# octet vs character count
    sub { CORE::length($s) == 11 },
    sub { mb::length($s)   == 5 },

# substr walks by character, keeping each multibyte char whole
    sub { mb::substr($s, 0, 1) eq $A },
    sub { mb::substr($s, 1, 1) eq $U2 },
    sub { mb::substr($s, 2, 1) eq $U3 },
    sub { mb::substr($s, 3, 1) eq $U4 },
    sub { mb::substr($s, 4, 1) eq $A },
    sub { mb::substr($s, -1, 1) eq $A },
    sub { mb::substr($s, 1, 3) eq ($U2 . $U3 . $U4) },

# index / rindex return character offsets, not octet offsets
    sub { mb::index($s, $U2)  == 1 },
    sub { mb::index($s, $U3)  == 2 },
    sub { mb::index($s, $U4)  == 3 },
    sub { mb::rindex($s, $A)  == 4 },
    sub { mb::index($s, $A)   == 0 },

# reverse keeps each character whole, only reorders them
    sub { mb::reverse($s) eq ($A . $U4 . $U3 . $U2 . $A) },

# chop removes one whole character from the end
    sub { my $c = $s; my $ch = mb::chop($c);
          ($ch eq $A) and (mb::length($c) == 4) },

# chop a string whose last character is the 4-octet char
    sub { my $c = $A . $U2 . $U3 . $U4; my $ch = mb::chop($c);
          ($ch eq $U4) and (mb::length($c) == 3) and ($c eq ($A . $U2 . $U3)) },

# the multibyte anchor: /./ (transpiled) steps one character at a time
    sub { my $code = mb::parse(q{my @c = $s =~ /(.)/g; scalar(@c)});
          (eval $code) == 5 },
    sub { my $code = mb::parse(q{my @c = $s =~ /(.)/g; $c[3]});
          (eval $code) eq $U4 },

# US-ASCII class [A-Z] matches only the two real "Z" chars (UTF-8 continuation
# octets are \x80-\xBF, so no ASCII is ever buried inside a multibyte char)
    sub { my $code = mb::parse(q{my $n = () = $s =~ /([A-Z])/g; $n});
          (eval $code) == 2 },

# getc-style lead dispatch: \xC2-\xDF => 2 octets, \xE0-\xEF => 3, \xF0-\xF4 => 4
    sub { ("\xC2" =~ /\A [\xC2-\xDF] \z/x) ? 1 : 0 },
    sub { ("\xE2" =~ /\A [\xE0-\xEF] \z/x) ? 1 : 0 },
    sub { ("\xF0" =~ /\A [\xF0-\xF4] \z/x) ? 1 : 0 },

# mb::getc reads one whole character at a time from a real filehandle: the
# 2/3/4-octet leads pull 1/2/3 more octets respectively
    sub { open(GETCFH,"@{[__FILE__]}.getc.tmp") or die $!; binmode GETCFH;
          my $c1 = mb::getc(*GETCFH); my $c2 = mb::getc(*GETCFH);
          my $c3 = mb::getc(*GETCFH); my $c4 = mb::getc(*GETCFH);
          my $c5 = mb::getc(*GETCFH); my $c6 = mb::getc(*GETCFH);
          close(GETCFH);
          ($c1 eq $A) and ($c2 eq $U2) and ($c3 eq $U3) and
          ($c4 eq $U4) and ($c5 eq $A) and (not defined $c6) },

# truncated input: a file that ends in the MIDDLE of a multibyte character.
# mb::getc must read the octets that are present, return them, and MUST NOT warn
# "uninitialized value" when the trailing octet(s) hit EOF. The next mb::getc
# then returns undef. Warnings are forced on with local $^W and captured with
# $SIG{__WARN__} so this stays a real guard even under `perl` (no -w). $w must
# stay empty.

# 2-octet char truncated after 1 of 2 octets
    sub { open(TRUNCFH,">@{[__FILE__]}.trunc.tmp") or die $!;
          binmode TRUNCFH; print TRUNCFH "\xC2"; close(TRUNCFH);
          my $w = ''; local $^W = 1; local $SIG{__WARN__} = sub { $w .= $_[0] };
          open(TRUNCFH,"@{[__FILE__]}.trunc.tmp") or die $!; binmode TRUNCFH;
          my $c1 = mb::getc(*TRUNCFH); my $c2 = mb::getc(*TRUNCFH);
          close(TRUNCFH); unlink("@{[__FILE__]}.trunc.tmp");
          ($c1 eq "\xC2") and (not defined $c2) and ($w eq '') },

# 3-octet char truncated after 1 of 3 octets
    sub { open(TRUNCFH,">@{[__FILE__]}.trunc.tmp") or die $!;
          binmode TRUNCFH; print TRUNCFH "\xE2"; close(TRUNCFH);
          my $w = ''; local $^W = 1; local $SIG{__WARN__} = sub { $w .= $_[0] };
          open(TRUNCFH,"@{[__FILE__]}.trunc.tmp") or die $!; binmode TRUNCFH;
          my $c1 = mb::getc(*TRUNCFH); my $c2 = mb::getc(*TRUNCFH);
          close(TRUNCFH); unlink("@{[__FILE__]}.trunc.tmp");
          ($c1 eq "\xE2") and (not defined $c2) and ($w eq '') },

# 3-octet char truncated after 2 of 3 octets
    sub { open(TRUNCFH,">@{[__FILE__]}.trunc.tmp") or die $!;
          binmode TRUNCFH; print TRUNCFH "\xE2\x82"; close(TRUNCFH);
          my $w = ''; local $^W = 1; local $SIG{__WARN__} = sub { $w .= $_[0] };
          open(TRUNCFH,"@{[__FILE__]}.trunc.tmp") or die $!; binmode TRUNCFH;
          my $c1 = mb::getc(*TRUNCFH); my $c2 = mb::getc(*TRUNCFH);
          close(TRUNCFH); unlink("@{[__FILE__]}.trunc.tmp");
          ($c1 eq "\xE2\x82") and (not defined $c2) and ($w eq '') },

# 4-octet char truncated after 1 of 4 octets
    sub { open(TRUNCFH,">@{[__FILE__]}.trunc.tmp") or die $!;
          binmode TRUNCFH; print TRUNCFH "\xF0"; close(TRUNCFH);
          my $w = ''; local $^W = 1; local $SIG{__WARN__} = sub { $w .= $_[0] };
          open(TRUNCFH,"@{[__FILE__]}.trunc.tmp") or die $!; binmode TRUNCFH;
          my $c1 = mb::getc(*TRUNCFH); my $c2 = mb::getc(*TRUNCFH);
          close(TRUNCFH); unlink("@{[__FILE__]}.trunc.tmp");
          ($c1 eq "\xF0") and (not defined $c2) and ($w eq '') },

# 4-octet char truncated after 2 of 4 octets
    sub { open(TRUNCFH,">@{[__FILE__]}.trunc.tmp") or die $!;
          binmode TRUNCFH; print TRUNCFH "\xF0\x9F"; close(TRUNCFH);
          my $w = ''; local $^W = 1; local $SIG{__WARN__} = sub { $w .= $_[0] };
          open(TRUNCFH,"@{[__FILE__]}.trunc.tmp") or die $!; binmode TRUNCFH;
          my $c1 = mb::getc(*TRUNCFH); my $c2 = mb::getc(*TRUNCFH);
          close(TRUNCFH); unlink("@{[__FILE__]}.trunc.tmp");
          ($c1 eq "\xF0\x9F") and (not defined $c2) and ($w eq '') },

# 4-octet char truncated after 3 of 4 octets
    sub { open(TRUNCFH,">@{[__FILE__]}.trunc.tmp") or die $!;
          binmode TRUNCFH; print TRUNCFH "\xF0\x9F\x98"; close(TRUNCFH);
          my $w = ''; local $^W = 1; local $SIG{__WARN__} = sub { $w .= $_[0] };
          open(TRUNCFH,"@{[__FILE__]}.trunc.tmp") or die $!; binmode TRUNCFH;
          my $c1 = mb::getc(*TRUNCFH); my $c2 = mb::getc(*TRUNCFH);
          close(TRUNCFH); unlink("@{[__FILE__]}.trunc.tmp");
          ($c1 eq "\xF0\x9F\x98") and (not defined $c2) and ($w eq '') },

# strict validity: the well-formed sample is valid
    sub { mb::valid($s) == 1 },
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
