#!perl

use strict;
use warnings;

use Test::More tests => 2;

use Cairo;
use Date::Simple;
use File::Temp qw(tmpnam);

use VS::Chart;

my $chart = VS::Chart->new(
    y_minor_ticks_count => 2,
    y_steps             => 10,
    y_grid              => 1,
    y_minor_ticks       => 1,
    y_minor_grid        => 1,
    y_labels            => 1,
    x_labels            => 1,
    y_ticks             => 1,
    show_y_min          => 1,
    x_ticks             => 1,
    x_grid              => 1,
    width => 640, height => 480,
    line_width          => 2,
    x_label_decimals    => 0,
    x_minor_ticks       => 1,
    x_minor_ticks_count => 2,
    x_minor_grid        => 1,
);

srand(100);

my @s = map { int(rand(100)) } 0..2;

my $d = Date::Simple->new("2000-01-01");
#my $d = 0;

for (0..52) {
    @s = map { $_ += -5 + rand(15) } @s;    
    $chart->add($d, @s);
    $d += 7;
}
$chart->set(x_column => 1);

my $path = tmpnam() . ".png";
$chart->set(max => $chart->_max * 1.01);
$chart->set(min => 0);
my $t = time();

$chart->render(type => 'line', to => $path);

ok(-e $path);
ok((stat($path))[7] > 0);
