# This file is encoded in US-ASCII.
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

# qr/ [A-Z] /-style hyphen ranges in a character class, for INFORMIX V6 ALS.
# The two-octet core [\x81-\x9F\xE0-\xFC][\x00-\xFF] is byte-for-byte identical
# to sjis and is already covered by t/3026_charclass_hyphen_sjis.t. What that
# test cannot cover is the interaction between the two-octet core and the
# three-octet \xFD[\xA1-\xFE][\x00-\xFF] user-defined plane that only exists in
# informixv6als, so this test spans all three lengths (one, two, three octets).
#
# Unlike sjis, informixv6als has a full one-octet universe of
# [\x00-\x80\xA0-\xDF\xFD-\xFF]: \xA0-\xDF and \xFD-\xFF ARE valid single
# octets here, and \xFD is doubly special because the SAME byte value is also
# the lead of the three-octet plane. So the single-octet limits must reach the
# top of that universe, not stop at \xDF: the set below carries \xA0 (bottom of
# the \xA0-\xDF katakana run) and \xFD, \xFE, \xFF (the top run) as bare
# one-octet endpoints. Those are exactly the codepoints that exercise
#   (a) the \xFD(?![\xA1-\xFE]) guard, so a one-octet range whose top reaches
#       \xFD-\xFF does not wrongly match the lead byte of a \xFD-plane char, and
#   (b) length-first ordering between the single octets \xFD-\xFF and the
#       three-octet \xFD-plane that sorts strictly after them.
# \x5C appears as a two-octet trailing octet (the DAMEMOJI backslash). mb
# orders codepoints length-first (every one-octet unit before every two-octet
# unit before every three-octet unit). mb is loaded with require and codepoints
# are built with pack(), so the source stays US-ASCII and runs on every perl
# from 5.005_03 up.

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
require mb;
mb::set_script_encoding('informixv6als');
use vars qw(@test);

my @limit_hex = qw(
00
7F
80
A0
DF
FD
FE
FF
8100
815C
9FFF
E000
FCFF
FDA100
FDFEFF
);

my @limit = ();
for my $limit (@limit_hex) {
    my $octet = pack('H*', $limit);
    push @limit, $octet;
}

for (my $i=0; $i <= $#limit; $i++) {
    for (my $j=$i; $j <= $#limit; $j++) {
        for (my $k=0; $k <= $#limit; $k++) {
            my $li = $limit[$i];
            my $lj = $limit[$j];
            my $lk = $limit[$k];
            if (
                ((CORE::length($lk) < CORE::length($li)) or ((CORE::length($lk) == CORE::length($li)) and ($lk lt $li)))
            ) {
                push @test, sub { eval mb::parse(qq{"$lk" =~ /[^$li-$lj]/}) };
                push @test, sub { eval mb::parse(qq{"$lk" !~  /[$li-$lj]/}) };
            }
            elsif (
                ((CORE::length($li) < CORE::length($lk)) or ((CORE::length($li) == CORE::length($lk)) and ($li le $lk)))
                and
                ((CORE::length($lk) < CORE::length($lj)) or ((CORE::length($lk) == CORE::length($lj)) and ($lk le $lj)))
            ) {
                push @test, sub { eval mb::parse(qq{"$lk" =~  /[$li-$lj]/}) };
                push @test, sub { eval mb::parse(qq{"$lk" !~ /[^$li-$lj]/}) };
            }
            elsif (
                ((CORE::length($lj) < CORE::length($lk)) or ((CORE::length($lj) == CORE::length($lk)) and ($lj lt $lk)))
            ) {
                push @test, sub { eval mb::parse(qq{"$lk" =~ /[^$li-$lj]/}) };
                push @test, sub { eval mb::parse(qq{"$lk" !~  /[$li-$lj]/}) };
            }
            else {
                die;
            }
        }
    }
}

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
