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

use Tk;
use Tk::RotatingGauge;

my ($w, $h)     = (200, 30);
my ($f, $t, $v) = (2, 7, 3);
my $mw = Tk::MainWindow->new;

# prettyfying tk app.
# see http://www.perltk.org/index.php?option=com_content&task=view&id=43&Itemid=37
$mw->optionAdd('*BorderWidth' => 1);


# easy one
{
    my $frame  = $mw->Frame->pack;
    my $policy = 'rotate';
    my $val    = 5;
    my $g = $frame->RotatingGauge(
        -width   => $w, -height  => $h,
        -from    => $f, -to      => $t,
        -visible => $v, -value   => $val,
        -indicator => 'green', -box => 'yellow',
    )->pack(-side=>'left', -expand=>1, -fill=>'both');

    $frame->Button(-text=>'-', -command=>sub{$val-=0.1;$g->value($val)})->pack(-side=>'left');
    $frame->Button(-text=>'+', -command=>sub{$val+=0.1;$g->value($val)})->pack(-side=>'left');
    $frame->Checkbutton(
        -text     => 'strict',
        -variable => \$policy,
        -onvalue  => 'strict',
        -offvalue => 'rotate',
        -command  => sub { $g->configure(-policy=>$policy); },
    )->pack(-side=>'left');
}

# with labels
{
    my $frame  = $mw->Frame->pack;
    my $policy = 'rotate';
    my $val    = 5;
    my $g = $frame->RotatingGauge(
        -width   => $w, -height  => $h,
        -from    => $f, -to      => $t,
        -visible => $v, -value   => $val,
        -labels => [ qw[ foo bar two three four five six ] ],
    )->pack(-side=>'left', -expand=>1, -fill=>'both');

    $frame->Button(-text=>'-', -command=>sub{$val-=0.1;$g->value($val)})->pack(-side=>'left');
    $frame->Button(-text=>'+', -command=>sub{$val+=0.1;$g->value($val)})->pack(-side=>'left');
    $frame->Checkbutton(
        -text     => 'strict',
        -variable => \$policy,
        -onvalue  => 'strict',
        -offvalue => 'rotate',
        -command  => sub { $g->configure(-policy=>$policy); },
    )->pack(-side=>'left');
}

# some kind of mileage counter
{
    my $frame  = $mw->Frame->pack;
    my $val = 0;
    my $g1 = $frame->RotatingGauge(
        -width   => $h, -height => 2 * $h,
        -from    => 0,  -to     => 10,
        -visible => $v, -value  => $val,
        -orient  => 'vert',
    )->pack(-side=>'left', -expand=>1, -fill=>'both');
    my $g2 = $frame->RotatingGauge(
        -width   => $h, -height  => 2 * $h,
        -from    => 0,  -to      => 10,
        -visible => $v, -value   => $val,
        -orient  => 'vert',
    )->pack(-side=>'left', -expand=>1, -fill=>'both');
    my $g3 = $frame->RotatingGauge(
        -width   => $h, -height  => 2 * $h,
        -from    => 0,  -to      => 10,
        -visible => $v, -value   => $val,
        -orient  => 'vert',
    )->pack(-side=>'left', -expand=>1, -fill=>'both');
    $frame->repeat( 25, sub {
        $val++;
        $g1->value($val/1000);
        $g2->value($val/100);
        $g3->value($val/10);
    } );
}

MainLoop;
exit;
