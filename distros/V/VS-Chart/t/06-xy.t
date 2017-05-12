#!perl

use strict;
use warnings;

use Test::More tests => 16;

use Cairo;
use Date::Simple;

BEGIN { use_ok("VS::Chart::Renderer::XY"); }

require VS::Chart;

my $rend = VS::Chart::Renderer::XY->new();
isa_ok($rend, "VS::Chart::Renderer::XY");
isa_ok($rend, "VS::Chart::Renderer");

is_deeply(VS::Chart->new(no_defaults => 1), { _defaults => 0 });

my $surface = Cairo::ImageSurface->create('argb32', 400, 400);

# Y Axis tests
{
    my $chart = VS::Chart->new(no_defaults => 1);
    my ($xl, $xr) = $rend->x_offsets($chart, $surface);
    is($xl, -1); 
    is($xr, 0.5);

    $chart->set(y_ticks => 1);
    ($xl, $xr) = $rend->x_offsets($chart, $surface);
    is($xl, -1); 
    is($xr, 0.5);

    $chart->set(y_minor_ticks => 1, y_ticks => 0);
    ($xl, $xr) = $rend->x_offsets($chart, $surface);
    is($xl, -1); 
    is($xr, 0.5);

    $chart->set(y_labels => 1, y_minor_ticks => 0);
    $chart->add(Date::Simple->new("2000-01-01"), 1);
    $chart->add(Date::Simple->new("2001-01-01"), 1);
    ($xl, $xr) = $rend->x_offsets($chart, $surface);
    ok($xl > 10); 
    is($xr, 0.5);

    $chart->set(y_labels => 0, x_labels => 1);
    ($xl, $xr) = $rend->x_offsets($chart, $surface);
    ok($xl > 10); 
    ok($xl > 10);
}

# X Axis tests
{
    my $chart = VS::Chart->new(x_labels => 0);
    my ($yt, $yb) = $rend->y_offsets($chart, $surface);
    is($yt, -1);
    is($yb, 0.5);
}