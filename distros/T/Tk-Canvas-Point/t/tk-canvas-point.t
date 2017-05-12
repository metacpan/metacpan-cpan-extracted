#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: tk-canvas-point.t,v 1.9 2009/11/10 19:46:24 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2002,2007,2009 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

use strict;

BEGIN {
    if (!eval q{
	use Test::More;
	use File::Temp qw(tempfile);
	1;
    }) {
	print "1..0 # skip: no Test::More and/or File::Temp module\n";
	exit;
    }
}

plan 'no_plan';

use Tk;

$ENV{BATCH} = 1 unless defined $ENV{BATCH};
$ENV{BATCH} = 0 if @ARGV && $ARGV[0] eq '-demo';

use_ok('Tk::Canvas::Point');

my $mw = eval { new MainWindow };
if (!$mw) {
    exit 0;
}

my $c = $mw->Canvas->pack(-fill => "both", -expand => 1);
$c->bind("all", "<1>" => sub {
	     my($c) = @_;
	     my(@tags) = $c->gettags("current");
	     warn "Tags of current item: @tags\n";
	     my(@coords) = $c->coords("current");
	     warn "Coords of current item: @coords\n";
	 });
my $status = "";
$c->bind("all", "<Enter>" => sub {
	     my($c) = @_;
	     $status = ($c->gettags("current"))[0];
	 });
$c->bind("all", "<Leave>" => sub {
	     my($c) = @_;
	     $status = "";
	 });
my @p;
if ($ENV{BATCH}) {
    $mw->update;
    create_points();
    $mw->update;
    for (1..10) {
	delete_last_point();
	$mw->update;
    }
    postscript(0);
    $mw->update;
} else {
    my $f = $mw->Frame->pack;
    $mw->Button(-text => "Create points",
		-command => sub { create_points() }
	       )->pack(-side => "left");
    $mw->Button(-text => "Delete last point",
		-command => sub { delete_last_point() },
	       )->pack(-side => "left");
    $mw->Button(-text => "PS",
		-command => sub { postscript(1) })->pack(-side => "left");
}
$mw->Label(-textvariable => \$status)->pack;

MainLoop if !$ENV{BATCH};

pass("Exited MainLoop");

sub create_points {
    for(1..100) {
	my $width = rand(20);
	push @p, $c->create('point',
			    rand($c->width),rand($c->height),
			    -width => $width,
			    -activefill => "white",
			    -activewidth => $width+2,
			    -fill => [qw(blue red green yellow black white)]->[rand(5)],
			    -tags => "tag".int(rand(100)),
			   );
    }
}

sub delete_last_point {
    $c->delete(pop @p) if @p;
}

sub postscript {
    my $display = shift;
    my(undef, $f) = tempfile(SUFFIX => "_tkcp.ps", UNLINK => !$display);
    $c->postscript(-file => $f);
    ok(-f $f, "Seen postscript file $f");
    open(F, $f) or die $!;
    my($firstline) = <F>;
    close F;
    like($firstline, qr/%!PS-Adobe-\d/, "Looks like a postscript file");
    system("gv $f &") if $display;
}

__END__
