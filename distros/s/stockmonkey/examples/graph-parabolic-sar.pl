#!/usr/bin/perl -Iblib/lib

BEGIN {
    my @mtime = map {(stat $_)[9]} qw(Makefile Makefile.PL);
    system (qw(perl Makefile.PL)) if $mtime[0] != $mtime[1];
    system (qw(make -f Makefile));
}

use strict;
use Math::Business::ParabolicSAR;
use GD::Graph::mixed;
use List::Util qw(min max);

my $sar = Math::Business::ParabolicSAR->recommended;

my @ohlc = @{do "msft_6-17-8.txt"};
my @data;

for my $p (@ohlc) {
    my $d = shift @$p;

    $sar->insert($p);

    my $x = 0;
    push @{$data[$x++]}, $d; # date
    push @{$data[$x++]}, $p->[-1]; # close
    push @{$data[$x++]}, $p; # ohlc
    push @{$data[$x++]}, $sar->query;
}

for(@data) {
    if( (my $k = @$_ - 62)>0 ) {
        splice @$_, 0, $k;
    }
}

my @all_points = grep {defined $_} map {ref $_ ? @$_ : $_} map {@$_} @data[1 .. $#data];
my $min_point  = min(@all_points);
my $max_point  = max(@all_points);

my $graph = GD::Graph::mixed->new(1000, 500);
   $graph->set_legend(qw(close ohlc Parabolic-SAR));
   $graph->set(
       y_label           => 'dollars NASDAQ:MSFT',
       x_label           => 'date',
       transparent       => 0,
       markers           => [qw(8)],
       dclrs             => [qw(lgray lblue lred)],
       types             => [qw(lines ohlc points)],
       y_min_value       => $min_point-0.2,
       y_max_value       => $max_point+0.2,
       y_number_format   => '%0.2f',
       x_labels_vertical => 1,

   ) or die $graph->error;

my $gd = $graph->plot(\@data) or die $graph->error;
open my $img, '>', ".graph.png" or die $!;
binmode $img;
print $img $gd->png;
close $img;

system(qw(eog .graph.png));

__END__
This controls the order of markers in points and linespoints graphs.  This should be a reference to an array of
numbers:

    $graph->set( markers => [3, 5, 6] );

Available markers are: 1: filled square, 2: open square, 3: horizontal cross, 4: diagonal cross, 5: filled dia-
mond, 6: open diamond, 7: filled circle, 8: open circle, 9: horizontal line, 10: vertical line.  Note that the
last two are not part of the default list.

Default: [1,2,3,4,5,6,7,8]
