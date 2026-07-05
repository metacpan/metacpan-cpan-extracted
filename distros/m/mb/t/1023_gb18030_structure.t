# This file is encoded in US-ASCII.
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

# GB18030 multibyte structure, verified directly through the runtime API. mb is
# loaded with require (no source filter), so this runs on every perl from
# 5.005_03 up. All multibyte bytes are written with \x escapes so the source
# stays US-ASCII.
#
# GB18030 characters:
#   A   US-ASCII single octet              "Z"                (\x5A)
#   T2  two octets                         \x81\x40           (2nd octet \x40)
#   T4  four octets                        \x81\x30\x81\x30   (2nd octet \x30)
# A lead \x81-\xFE reads a second octet; if that second octet is \x30-\x39 the
# character is four octets (two more are read), otherwise it is two octets. So
# T2's \x40 stops at two octets while T4's \x30 continues to four. The \x30 and
# \x40 octets buried inside must NOT be seen as character boundaries.

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
require mb;
use vars qw(@test);

mb::set_script_encoding('gb18030');

my $A  = "\x5A";                 # "Z"
my $T2 = "\x81\x40";             # 2-octet (2nd octet \x40, not \x30-\x39)
my $T4 = "\x81\x30\x81\x30";     # 4-octet (2nd octet \x30, in \x30-\x39)
my $s  = $A . $T2 . $T4 . $A;    # 1+2+4+1 octets, 4 characters

BEGIN { open(GETCFH,">@{[__FILE__]}.getc.tmp") or die $!; binmode GETCFH; print GETCFH "\x5A\x81\x40\x81\x30\x81\x30\x5A"; close(GETCFH); }
END   { unlink("@{[__FILE__]}.getc.tmp") }

@test = (

# get/set round trip
    sub { mb::get_script_encoding() eq 'gb18030' },

# octet vs character count
    sub { CORE::length($s) == 8 },
    sub { mb::length($s)   == 4 },

# substr walks by character, keeping each multibyte char whole
    sub { mb::substr($s, 0, 1) eq $A },
    sub { mb::substr($s, 1, 1) eq $T2 },
    sub { mb::substr($s, 2, 1) eq $T4 },   # the 4-octet char, undivided
    sub { mb::substr($s, 3, 1) eq $A },
    sub { mb::substr($s, -1, 1) eq $A },
    sub { mb::substr($s, 1, 2) eq ($T2 . $T4) },

# index / rindex return character offsets, not octet offsets
    sub { mb::index($s, $T2)  == 1 },
    sub { mb::index($s, $T4)  == 2 },
    sub { mb::rindex($s, $A)  == 3 },
    sub { mb::index($s, $A)   == 0 },

# the octets buried inside multibyte chars are not findable as characters
    sub { mb::index($s, "\x40") == -1 },   # buried in T2
    sub { mb::index($s, "\x30") == -1 },   # buried in T4

# reverse keeps each character whole, only reorders them
    sub { mb::reverse($s) eq ($A . $T4 . $T2 . $A) },

# chop removes one whole character from the end
    sub { my $c = $s; my $ch = mb::chop($c);
          ($ch eq $A) and (mb::length($c) == 3) and ($c eq ($A . $T2 . $T4)) },

# chop a string whose last character is the 4-octet char
    sub { my $c = $A . $T2 . $T4; my $ch = mb::chop($c);
          ($ch eq $T4) and (mb::length($c) == 2) and ($c eq ($A . $T2)) },

# the multibyte anchor: /./ (transpiled) steps one character at a time
    sub { my $code = mb::parse(q{my @c = $s =~ /(.)/g; scalar(@c)});
          (eval $code) == 4 },
    sub { my $code = mb::parse(q{my @c = $s =~ /(.)/g; $c[2]});
          (eval $code) eq $T4 },

# US-ASCII class [A-Z] matches only the two real "Z" chars, never the octets
# buried inside T2/T4
    sub { my $code = mb::parse(q{my $n = () = $s =~ /([A-Z])/g; $n});
          (eval $code) == 2 },

# getc-style lead dispatch: \x81-\xFE is a lead; a following \x30-\x39 makes the
# character four octets, otherwise two
    sub { ("\x81" =~ /\A [\x81-\xFE] \z/x) ? 1 : 0 },
    sub { ("\x81\x30" =~ /\A [\x81-\xFE] [\x30-\x39] \z/x) ? 1 : 0 },  # -> 4 octets
    sub { ("\x81\x40" =~ /\A [\x81-\xFE] [\x30-\x39] \z/x) ? 0 : 1 },  # -> 2 octets

# mb::getc reads one whole character at a time from a real filehandle: the
# 2-octet T2 stops at two octets, the 4-octet T4 pulls three more
    sub { open(GETCFH,"@{[__FILE__]}.getc.tmp") or die $!; binmode GETCFH;
          my $c1 = mb::getc(*GETCFH); my $c2 = mb::getc(*GETCFH);
          my $c3 = mb::getc(*GETCFH); my $c4 = mb::getc(*GETCFH);
          my $c5 = mb::getc(*GETCFH);
          close(GETCFH);
          ($c1 eq $A) and ($c2 eq $T2) and ($c3 eq $T4) and
          ($c4 eq $A) and (not defined $c5) },

# truncated input: a file that ends in the MIDDLE of a multibyte character.
# mb::getc must read the octets that are present, return them, and MUST NOT warn
# "uninitialized value" when the trailing octet(s) hit EOF. The next mb::getc
# then returns undef. Warnings are forced on with local $^W and captured with
# $SIG{__WARN__} so this stays a real guard even under `perl` (no -w). $w must
# stay empty.

# lead only (1 of 2/4 octets)
    sub { open(TRUNCFH,">@{[__FILE__]}.trunc.tmp") or die $!;
          binmode TRUNCFH; print TRUNCFH "\x81"; close(TRUNCFH);
          my $w = ''; local $^W = 1; local $SIG{__WARN__} = sub { $w .= $_[0] };
          open(TRUNCFH,"@{[__FILE__]}.trunc.tmp") or die $!; binmode TRUNCFH;
          my $c1 = mb::getc(*TRUNCFH); my $c2 = mb::getc(*TRUNCFH);
          close(TRUNCFH); unlink("@{[__FILE__]}.trunc.tmp");
          ($c1 eq "\x81") and (not defined $c2) and ($w eq '') },

# 4-octet char truncated after 2 of 4 octets (\x30 selected the 4-octet form)
    sub { open(TRUNCFH,">@{[__FILE__]}.trunc.tmp") or die $!;
          binmode TRUNCFH; print TRUNCFH "\x81\x30"; close(TRUNCFH);
          my $w = ''; local $^W = 1; local $SIG{__WARN__} = sub { $w .= $_[0] };
          open(TRUNCFH,"@{[__FILE__]}.trunc.tmp") or die $!; binmode TRUNCFH;
          my $c1 = mb::getc(*TRUNCFH); my $c2 = mb::getc(*TRUNCFH);
          close(TRUNCFH); unlink("@{[__FILE__]}.trunc.tmp");
          ($c1 eq "\x81\x30") and (not defined $c2) and ($w eq '') },

# 4-octet char truncated after 3 of 4 octets
    sub { open(TRUNCFH,">@{[__FILE__]}.trunc.tmp") or die $!;
          binmode TRUNCFH; print TRUNCFH "\x81\x30\x81"; close(TRUNCFH);
          my $w = ''; local $^W = 1; local $SIG{__WARN__} = sub { $w .= $_[0] };
          open(TRUNCFH,"@{[__FILE__]}.trunc.tmp") or die $!; binmode TRUNCFH;
          my $c1 = mb::getc(*TRUNCFH); my $c2 = mb::getc(*TRUNCFH);
          close(TRUNCFH); unlink("@{[__FILE__]}.trunc.tmp");
          ($c1 eq "\x81\x30\x81") and (not defined $c2) and ($w eq '') },

# strict validity: the well-formed sample is valid
    sub { mb::valid($s) == 1 },
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
