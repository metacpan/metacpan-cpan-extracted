#!/usr/bin/perl -w

use Tk;
use Tk::DatePick;
use strict;

my $main = MainWindow->new(-title => 'DatePickDemo');
my ($tmp,$l4,$l5,$l6);
my $l1 = $main->Label(-text => 'No Options')->pack();
my $d1 = $main->DatePick()->pack();
my $l2 = $main->Label(-text => 'Calendar Year')->pack();
my $d2 = $main->DatePick(-text => '21/5/2015',
			-yeartype => 'calyear')->pack();
my $l3 = $main->Label(-text => 'Financial Year')->pack();
my $d3 = $main->DatePick(-text => '1/6/1915',
			-yeartype => 'finyear')->pack();

my $but = $main->Button(-text => 'Display Selection Results',
			-command =>
			sub
			{
			$tmp = $d1->cget('-text');
			$l4->configure(-text => $tmp);
			$tmp = $d2->cget('-text');
			$l5->configure(-text => $tmp);
			$tmp = $d3->cget('-text');
			$l6->configure(-text => $tmp);
			}
			)->pack();
$l4 = $main->Label()->pack();
$l5 = $main->Label()->pack();
$l6 = $main->Label()->pack();

MainLoop;

#-------------------------------------------------
