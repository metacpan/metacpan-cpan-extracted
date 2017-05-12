#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Try::Tiny;
use X11::Xlib ':all';
use FindBin;
use lib "$FindBin::Bin/lib";
use X11::SandboxServer;

plan skip_all => "No X11 Server available"
    unless $ENV{DISPLAY};

plan skip_all => 'Xcomposite client lib is not available'
    unless X11::Xlib->can('XCompositeVersion');

my $x= try { X11::SandboxServer->new(title => $FindBin::Script) };
plan skip_all => 'Need Xephyr to run Xcomposite tests'
    unless defined $x;

my $display= $x->client;
plan skip_all => 'Xcomposite not supported by server'
    unless $display->XCompositeQueryVersion;

sub err(&) { my $code= shift; my $ret; { local $@= ''; eval { $code->() }; $display->flush_sync; $ret= $@; } $ret }

my ($root, $overlay, $region);
note "local Xc ver = ".X11::Xlib::XCompositeVersion()." server Xc ver = ".join('.', $display->XCompositeQueryVersion);
is( err{ $root= $display->root_window }, '', 'get root window' );
note "root = $root";
is( err{ $display->XCompositeRedirectSubwindows($root, CompositeRedirectAutomatic) }, '', 'XCompositeRedirectSubwindows' );
is( err{ $display->XSelectInput($root, SubstructureNotifyMask) }, '', 'XSelectInput' );
is( err{ $overlay= $display->XCompositeGetOverlayWindow($root) }, '', 'XCompositeGetOverlayWindow' );
note "overlay = $overlay";

SKIP: {
    skip "XFixes not available", 4
        unless X11::Xlib->can('XFixesCreateRegion');
    is( err{ $region= $display->XFixesCreateRegion([]) }, '', 'XFixesCreateRegion' );
    note "region = $region";
    is( err{ $display->XFixesSetWindowShapeRegion($overlay, ShapeBounding, 0, 0, 0) }, '', 'XFixesSetWindowShapeRegion' );
    is( err{ $display->XFixesSetWindowShapeRegion($overlay, ShapeInput, 0, 0, $region) }, '', 'XFixesSetWindowShapeRegion' );
    is( err{ $display->XFixesDestroyRegion($region) }, '', 'XFixesDestroyRegion' );
}

done_testing;
