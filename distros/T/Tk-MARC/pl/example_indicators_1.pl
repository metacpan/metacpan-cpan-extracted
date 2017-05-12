#!/usr/bin/perl
BEGIN{unshift @INC, "./blib/lib"}
use Tk;
use Tk::MARC::Indicators;

my $mw = MainWindow->new;
$mw->title("Editor Test");
$mw->MARC_Indicators(-field => '245',
		     -ind1 => '0',
		     -ind2 => '1',
                   )->pack;

MainLoop;
