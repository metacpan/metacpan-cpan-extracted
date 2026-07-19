# This file is encoded in US-ASCII.
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

# qr/ [A-Z] /-style hyphen ranges in a character class, for Johab (code page
# 1361, KS X 1001:1992 annex 3). Johab has a discontinuous two-octet lead
# [\x81-\xD3\xD8-\xDE\xE0-\xF9] (hangul \x81-\xD3, symbols \xD8-\xDE, hanja
# \xE0-\xF9, per Microsoft CRT mbctype.c) and NO single high octet: the only
# single-octet unit is US-ASCII [\x00-\x7F]. Because the lead is discontinuous
# the contiguous-lead sjis/big5 helper would mis-split a range, so mb uses a
# dedicated list_all_by_hyphen_johab_like (the same reason hp15 was made a
# dedicated helper). The limits below exercise all three lead regions, both of
# the inter-region gaps (\xD4-\xD7 and \xDF), the trailing-octet extremes, and
# the DAMEMOJI trailing octet \x5C. mb orders codepoints length-first (every
# one-octet unit before every two-octet unit). mb is loaded with require and
# codepoints are built with pack(), so the source stays US-ASCII and runs on
# every perl from 5.005_03 up.

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
require mb;
mb::set_script_encoding('johab');
use vars qw(@test);

my @limit_hex = qw(
00
7F
8100
815C
81FF
D300
D3FF
D800
D85C
DE00
DEFF
E000
E05C
F900
F9FF
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
