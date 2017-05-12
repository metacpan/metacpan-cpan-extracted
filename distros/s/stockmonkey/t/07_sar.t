#!/usr/bin/perl

use Test;
use Math::Business::ParabolicSAR;
use Data::Dumper;

my @sarz = (
    [ 28.4, '6/5' ],
    [ 28.3, '6/6' ],
    [ 28.2, '6/9' ],
    [ 27.3, '6/10' ],
    [ 28.3, '6/11' ],
    [ 27.2, '6/12' ],
    [ 27.2, '6/13' ],
    [ 27.3, '6/16' ],
    [ 27.4, '6/17' ],
);

plan tests => 0+@sarz;

my $sar = recommended Math::Business::ParabolicSAR;

if( -f "msft_6-17-8.txt" ) {
    my $ohlc = do "msft_6-17-8.txt";
    die $! if $!;
    die $@ if $@;
    die "unknown error: " . Dumper($ohlc) unless ref($ohlc) and @$ohlc > 10;

    my @totest = splice @$ohlc, -1*@sarz;

    @$ohlc = grep { shift @$_ } @$ohlc; # lose the leading date column

    $sar->insert( @$ohlc );

    for my $row (@totest) {
        my $date = shift @$row;
        $sar->insert( $row );

        my $q = $sar->query;
        my $p = shift @sarz;
        my $d = abs($q-$p->[0]);

        if( $d <= 0.2 ) {
            ok(1);

        } else {
            warn " \e[31mfailed $date/$p->[1] \e[1;33m$p->[0] != $q\e[m\n";
            ok(0);
        }
    }

} else {
    die "bad MANIFEST?";
}

