# This file is encoded in US-ASCII.
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

# qr/ [A-Z] /-style hyphen ranges in a character class, for HP-15.
# HP-15 has a discontinuous two-octet lead [\x80-\xA0\xE0-\xFE] with the single
# octets \xA1-\xDF (katakana) sitting between the two lead ranges and the single
# octet \xFF above them. The limits below exercise both lead ranges, the
# single-octet gap, the trailing-octet extremes, and the DAMEMOJI trailing
# octet \x5C. mb orders codepoints length-first (every one-octet unit before
# every two-octet unit). mb is loaded with require and codepoints are built
# with pack(), so the source stays US-ASCII and runs on every perl from
# 5.005_03 up.

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
require mb;
mb::set_script_encoding('hp15');
use vars qw(@test);

my @limit_hex = qw(
00
7F
A1
DF
FF
8000
805C
80FF
A021
A0FF
E000
E05C
E0FF
FE00
FEFF
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
