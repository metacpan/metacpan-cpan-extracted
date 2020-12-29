# This file is encoded in GB18030.
die "This file is not encoded in GB18030.\n" if 'дв' ne "\xA4\xA2";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
mb::set_script_encoding('gb18030');
use vars qw(@test);

my @limit_hex = qw(
00
7F
8140
817E
8180
81FE
FE40
FE7E
FE80
FEFE
81308130
81308139
8130FE30
8130FE39
81398130
81398139
8139FE30
8139FE39
FE308130
FE308139
FE30FE30
FE30FE39
FE398130
FE398139
FE39FE30
FE39FE39
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
