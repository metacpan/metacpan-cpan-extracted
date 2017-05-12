
use strict;
use Test;

use Math::Business::WMA;

my $N   = 13;
my $Dp  = 250;
my $wma = new Math::Business::WMA($N);

my @data = @{do "rand.data" or die $!}[0 .. $N*$Dp];
my @hand;

for my $i ($N-1 .. $#data) {
    my @ld = grep {defined $_} @data[ $i-($N-1) .. $i ];

    die "hrm" unless @ld == $N;

    my $x = 1;
    my $den = ($N * ($N+1)) / 2;
    my $num = 0;
       $num+= $_ for map { $_*$x++ } @ld;

    $hand[$i] = $num/$den;

  # my $sum = 0;
  #    $sum += $_ for @ld;
  # warn "ld=(@ld); N=$N; hand=$hand[$i]; den=$den; \e[33mnum=$num\e[m; sum=$sum";
}

plan tests => 2*@data + 11*2;

for my $i (0 .. $#data) {
    $wma->insert($data[$i]);

    my $w = $wma->query;

    ok($w, $hand[$i]);

    if( defined $w ) {
        ok(($w <= 11 and $w >= 3)?"YES":"not within sane numeric boundaries", "YES");

    } else {
        ok(1);
    }
}

# from a spreadsheet
@data = (10.00, 9.00, 11.00, 3.00, 10.00, 3.00, 4.00, 4.00, 5.00, 5.00, 7.00);
@hand = (undef, undef, undef, undef, 8.20, 6.33, 5.27, 4.53, 4.60, 4.53, 5.47);
$wma = new Math::Business::WMA(5);

for my $i (0 .. $#data) {
    $wma->insert($data[$i]);

    if( defined(my $w = $wma->query) ) {
        my $d = abs($hand[$i] - $w);

        ok($d < 0.01);
        ok(($w <= 11 and $w >= 3)?"YES":"not within sane numeric boundaries", "YES");

    } else {
        ok(1);
        ok(1);
    }
}
