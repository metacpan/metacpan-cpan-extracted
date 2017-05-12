#!/usr/bin/perl
# 
# This file is part of Tk-RotatingGauge
# 
# This software is copyright (c) 2007 by Jerome Quelin.
# 
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# 

use strict;
use warnings;

use FindBin qw{ $Bin };
use lib "$Bin/../lib";

use DateTime;
use Time::HiRes qw{ time };
use Tk;
use Tk::RotatingGauge;

my $SECS = 1000;
my $MINS = 60 * $SECS;

my $width  = 1000;
my $height = 30;
my $now = DateTime->from_epoch( epoch => time, time_zone=>'local' );

my $mw = Tk::MainWindow->new;
my $c_secs = $mw->RotatingGauge(
    -width   => $width, -height  => $height,
    -value   => $now->fractional_second,
    -from    => 0,
    -to      => 60,
    -visible => 30,
)->pack(-side=>'top');
my $c_mins = $mw->RotatingGauge(
    -width   => $width, -height  => $height,
    -value   => $now->minute + $now->second / 60,
    -from    => 0,
    -to      => 60,
    -visible => 30,
)->pack(-side=>'top');
my $c_hours = $mw->RotatingGauge(
    -width   => $width, -height  => $height,
    -value   => $now->hour + $now->minute / 60,
    -from    => 0,
    -to      => 24,
    -visible => 12,
)->pack(-side=>'top');
my $c_wdays = $mw->RotatingGauge(
    -width   => $width, -height  => $height,
    -value   => $now->day_of_week + $now->hour / 24 + $now->minute / 3600,
    -from    => 1,
    -to      => 8,
    -visible => 4,
    -labels  => [ qw[ foo Monday Tuesday Wednesday Thursday Friday Saturday Sunday ] ],
)->pack(-side=>'top');
my $c_days = $mw->RotatingGauge(
    -width   => $width, -height  => $height,
    -value   => $now->day + $now->hour / 24 + $now->minute / 3600,
    -from    => 1,
    -to      => 32,
    -visible => 16,
)->pack(-side=>'top');
my $c_mons = $mw->RotatingGauge(
    -width   => $width, -height  => $height,
    -value   => $now->month + $now->day / 32 + $now->hour / 768, # 768=24*32
    -from    => 1,
    -to      => 13,
    -visible => 6,
    -labels  => [ qw[ foo January February March April May June July
                      August September October November December ] ],
)->pack(-side=>'top');
my $c_years = $mw->RotatingGauge(
    -width   => $width, -height  => $height,
    -value   => $now->year + $now->day_of_year / 366,
    -from    => $now->year - 10,
    -to      => $now->year + 10,
    -visible => 3,
)->pack(-side=>'top');


$mw->repeat( 50,   \&update_secs );
$mw->repeat( 1 * $SECS, \&update_mins );
$mw->repeat( 1 * $MINS, \&update_rest );
MainLoop;
exit;

sub update_secs {
    my $dt = DateTime->from_epoch( epoch => time ); # need hires precision
    $c_secs->value( $dt->fractional_second );
}
sub update_mins {
    my $dt = DateTime->now;
    $c_mins->value( $dt->minute + $dt->second / 60 );
}
sub update_rest {
    my $dt = DateTime->from_epoch( epoch=>time, time_zone=>'local' );
    $c_hours->value( $dt->hour + $dt->minute / 60 );
    $c_wdays->value( $dt->day_of_week + $dt->hour / 24 + $dt->minute / 3600 );
    $c_days ->value( $dt->day + $dt->hour / 24 + $dt->minute / 3600 );
    $c_mons ->value( $dt->month + $dt->day / 32 + $dt->hour / 768 );
    $c_years->value( $dt->year + $dt->day_of_year / 366 );
}
