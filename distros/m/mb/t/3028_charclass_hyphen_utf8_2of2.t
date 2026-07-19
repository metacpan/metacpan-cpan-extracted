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
DFBF
E0A080
EFBFBF
F0908080
F09080BF
F090BF80
F090BFBF
F0BF8080
F0BF80BF
F0BFBF80
F0BFBFBF
F1808080
F18080BF
F180BF80
F180BFBF
F1BF8080
F1BF80BF
F1BFBF80
F1BFBFBF
F3808080
F38080BF
F380BF80
F380BFBF
F3BF8080
F3BF80BF
F3BFBF80
F3BFBFBF
F4808080
F48080BF
F480BF80
F480BFBF
F48F8080
F48F80BF
F48FBF80
F48FBFBF
);

my @limit = ();
for my $limit (@limit_hex) {
    my $octet = pack('H*', $limit);
    push @limit, $octet;
}

for (my $i=0; $i <= $#limit; $i++) {
    for (my $j=$i; $j <= $#limit; $j++) {
        my $li = $limit[$i];
        my $lj = $limit[$j];

        # Transpile and eval-compile the two character classes once per
        # ($i,$j) instead of once per subtest.  The regular expression
        # depends only on ($li,$lj), not on $lk, so hoisting mb::parse()
        # and the eval compilation out of the $k loop cuts the number of
        # transpilations from n**3 to n**2 while every subtest still
        # exercises exactly the same transpiled pattern against exactly
        # the same octets with the same expected result (CPAN smokers on
        # slow machines timed out on the n**3 version).  A compilation
        # failure makes the closure undef, so every subtest of that
        # ($i,$j) reports not ok -- the same visible result as before.
        my $match_in  = eval('sub { local $_ = $_[0]; (' . mb::parse(q{$_ =~  /[} . $li . '-' . $lj . q{]/}) . ') }');
        my $match_out = eval('sub { local $_ = $_[0]; (' . mb::parse(q{$_ =~ /[^} . $li . '-' . $lj . q{]/}) . ') }');

        for (my $k=0; $k <= $#limit; $k++) {
            my $lk = $limit[$k];
            if (
                ((CORE::length($lk) < CORE::length($li)) or ((CORE::length($lk) == CORE::length($li)) and ($lk lt $li)))
            ) {
                push @test, sub { $match_out and     $match_out->($lk) };
                push @test, sub { $match_in  and not $match_in->($lk)  };
            }
            elsif (
                ((CORE::length($li) < CORE::length($lk)) or ((CORE::length($li) == CORE::length($lk)) and ($li le $lk)))
                and
                ((CORE::length($lk) < CORE::length($lj)) or ((CORE::length($lk) == CORE::length($lj)) and ($lk le $lj)))
            ) {
                push @test, sub { $match_in  and     $match_in->($lk)  };
                push @test, sub { $match_out and not $match_out->($lk) };
            }
            elsif (
                ((CORE::length($lj) < CORE::length($lk)) or ((CORE::length($lj) == CORE::length($lk)) and ($lj lt $lk)))
            ) {
                push @test, sub { $match_out and     $match_out->($lk) };
                push @test, sub { $match_in  and not $match_in->($lk)  };
            }
            else {
                die;
            }
        }
    }
}

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
