# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xE3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
mb::set_script_encoding('utf8');
use vars qw(@test);

my @limit_hex = qw(
00
7F
C280
C2BF
DF80
DFBF
E0A080
E0A0BF
E0BF80
E0BFBF
E18080
E180BF
E1BF80
E1BFBF
EC8080
EC80BF
ECBF80
ECBFBF
ED8080
ED80BF
ED9F80
ED9FBF
EE8080
EE80BF
EEBF80
EEBFBF
EF8080
EF80BF
EFBF80
EFBFBF
F0908080
F48FBFBF
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
