#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#

use strict;

BEGIN {
    if (!eval q{
	use Test::More;
	1;
    }) {
	print "1..0 # skip: no Test::More module\n";
	exit;
    }
}

use Tk;
use Tk::DragDrop;
use Tk::DropSite;

$ENV{BATCH} = 1 if !defined $ENV{BATCH};

my $top = eval { tkinit };
if (!Tk::Exists($top)) {
    plan skip_all => 'Cannot create MainWindow';
    exit 0;
}

plan tests => 3;

use_ok('Tk::WidgetDump');

$top->geometry('+10+10');
$top->gridRowconfigure($_, -weight => 1) for (0..4);
$top->gridColumnconfigure($_, -weight => 1) for (0..1);

my %w;

my $row = 0;
foreach my $w_def (['Label'],
		   ['Entry'],
		   ['Button'],
		   ['Listbox', -height => 3],
		   ['Canvas', -width => 200, -height => 50],
		   ['Text', -width => 40, -height => 4]
		  ) {
    my($w,@opts) = @$w_def;
    $top->Label(-text => $w . ": ")->grid(-row => $row, -column => 0, -sticky => "nw");
    $w{$w} = $top->$w(@opts)->grid(-row => $row, -column => 1, -sticky => "eswn");
    $row++;
}

$w{Canvas}->createLine(0,0,100,100);
$w{Canvas}->createText(20,20,-text =>42);

$w{Label}->DragDrop
    (-event        => '<Shift-Control-B1-Motion>',
     -sitetypes    => 'Local',
     -startcommand => sub { warn "dragging" },
    );

$w{Button}->DropSite
    (-droptypes   => 'Local',
     -dropcommand => sub { warn "dropping" },
    );

# code references are evil:
$top->{EvilCode} = sub { print "test " };

$top->update;
my $wd = eval { $top->WidgetDump; };
is($@, "", "WidgetDump call");
isa_ok $wd, 'Tk::WidgetDump';
$wd->geometry('+20+20');

$top->after(1*1000, sub { $top->destroy }) if $ENV{BATCH};
MainLoop;

