#!/usr/local/bin/perl -w
use Tk;
use lib './blib/lib'; use CollapsableFrame;
use Tk::widgets qw/LabEntry/;
use strict;

my $mw = MainWindow->new;

my $cf = $mw->CollapsableFrame(
    -background => 'lightblue',
    -height     => 110,
    -title      => 'Copy Details',
    -width      => 300,
);
$cf->pack(qw/-fill x -expand 1/);

my $cf_frame = $cf->Subwidget('colf');

# Populate the CollapsableFrame with detail information.

my ($file, $from, $to, $bytes) =
    ('Makefile.PL', '/home/bug', '/tmp', '1,847');
foreach my $item (
        ['Copying',      \$file],
        ['From',         \$from],
        ['To',           \$to],
        ['Bytes Copied', \$bytes],
    ) {
    my $l = $item->[0] . ':';
    my $le = $cf_frame->LabEntry(
        -background          => 'lightgreen',
        -highlightbackground => 'blue',
        -label               => ' ' x (13 - length $l) . $l,
        -labelBackground     => 'lightgreen',
        -labelPack           => [qw/-side left -anchor w/],
        -labelFont           => '9x15bold',
        -relief              => 'flat',
        -state               => 'disabled',
        -textvariable        => $item->[1],
        -width               => 35,
    );
    $le->pack(qw/ -fill x -expand 1/);
}
 
MainLoop;
