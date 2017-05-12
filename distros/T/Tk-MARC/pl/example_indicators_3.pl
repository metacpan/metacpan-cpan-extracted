#!/usr/bin/perl
BEGIN{unshift @INC, "./blib/lib"}
use Tk;
use Tk::MARC::Indicators;

my $mw = MainWindow->new;
$mw->title("Editor Test");
my $TkInd = $mw->MARC_Indicators(-field => '245',
				 -ind1 => '0',
				 -ind2 => '1',
				 )->pack;
$mw->Button(-text => "1", -command => sub { print $TkInd->get(1) . $/; })->pack(-side => 'left');
$mw->Button(-text => "2", -command => sub { print $TkInd->get(2) . $/; })->pack(-side => 'left');
# These two should fail:
$mw->Button(-text => "x", -command => sub { print $TkInd->get() . $/; })->pack(-side => 'left');
$mw->Button(-text => "3", -command => sub { print $TkInd->get(3) . $/; })->pack(-side => 'left');

MainLoop;

