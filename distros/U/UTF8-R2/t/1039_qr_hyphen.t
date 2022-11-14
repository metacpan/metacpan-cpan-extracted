# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use UTF8::R2;
use vars qw(@test);

tie my %r2, 'UTF8::R2';

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

$| = 1;
print "1..200508\n";

my $t = 1;
for (my $i=0; $i <= $#limit; $i++) {
    for (my $j=$i; $j <= $#limit; $j++) {
        for (my $k=0; $k <= $#limit; $k++) {
            if (
                ((CORE::length($limit[$k]) < CORE::length($limit[$i])) or ((CORE::length($limit[$k]) == CORE::length($limit[$i])) and ($limit[$k] lt $limit[$i])))
            ) {
                if ($limit[$k] =~ $r2{qr/[^$limit[$i]-$limit[$j]]/}) {
                    printf(qq{ok $t - "%s" =~ [^%s-%s]\n}, uc unpack('H*',$limit[$k]), uc unpack('H*',$limit[$i]), uc unpack('H*',$limit[$j]));
                }
                else {
                    printf(qq{not ok $t - "%s" =~ [^%s-%s]\n}, uc unpack('H*',$limit[$k]), uc unpack('H*',$limit[$i]), uc unpack('H*',$limit[$j]));
                }
                $t++;

                if ($limit[$k] !~ $r2{qr/[$limit[$i]-$limit[$j]]/}) {
                    printf(qq{ok $t - "%s" !~ [%s-%s]\n}, uc unpack('H*',$limit[$k]), uc unpack('H*',$limit[$i]), uc unpack('H*',$limit[$j]));
                }
                else {
                    printf(qq{not ok $t - "%s" !~ [%s-%s]\n}, uc unpack('H*',$limit[$k]), uc unpack('H*',$limit[$i]), uc unpack('H*',$limit[$j]));
                }
                $t++;
            }
            elsif (
                ((CORE::length($limit[$i]) < CORE::length($limit[$k])) or ((CORE::length($limit[$i]) == CORE::length($limit[$k])) and ($limit[$i] le $limit[$k])))
                and
                ((CORE::length($limit[$k]) < CORE::length($limit[$j])) or ((CORE::length($limit[$k]) == CORE::length($limit[$j])) and ($limit[$k] le $limit[$j])))
            ) {
                if ($limit[$k] =~ $r2{qr/[$limit[$i]-$limit[$j]]/}) {
                    printf(qq{ok $t - "%s" =~ [%s-%s]\n}, uc unpack('H*',$limit[$k]), uc unpack('H*',$limit[$i]), uc unpack('H*',$limit[$j]));
                }
                else {
                    printf(qq{not ok $t - "%s" =~ [%s-%s]\n}, uc unpack('H*',$limit[$k]), uc unpack('H*',$limit[$i]), uc unpack('H*',$limit[$j]));
                }
                $t++;
            }
            elsif (
                ((CORE::length($limit[$j]) < CORE::length($limit[$k])) or ((CORE::length($limit[$j]) == CORE::length($limit[$k])) and ($limit[$j] lt $limit[$k])))
            ) {
                if ($limit[$k] =~ $r2{qr/[^$limit[$i]-$limit[$j]]/}) {
                    printf(qq{ok $t - "%s" =~ [^%s-%s]\n}, uc unpack('H*',$limit[$k]), uc unpack('H*',$limit[$i]), uc unpack('H*',$limit[$j]));
                }
                else {
                    printf(qq{not ok $t - "%s" =~ [^%s-%s]\n}, uc unpack('H*',$limit[$k]), uc unpack('H*',$limit[$i]), uc unpack('H*',$limit[$j]));
                }
                $t++;

                if ($limit[$k] !~ $r2{qr/[$limit[$i]-$limit[$j]]/}) {
                    printf(qq{ok $t - "%s" !~ [%s-%s]\n}, uc unpack('H*',$limit[$k]), uc unpack('H*',$limit[$i]), uc unpack('H*',$limit[$j]));
                }
                else {
                    printf(qq{not ok $t - "%s" !~ [%s-%s]\n}, uc unpack('H*',$limit[$k]), uc unpack('H*',$limit[$i]), uc unpack('H*',$limit[$j]));
                }
                $t++;
            }
            else {
                die;
            }
        }
    }
}

__END__
