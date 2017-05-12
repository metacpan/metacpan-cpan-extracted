#!/usr/bin/perl -w

use Tk;
use Tk::ReportBox;
use strict;
my $main = MainWindow->new(-title => 'ReportBox Demo');
my ($tmp,$l4,$l1);

my $but = $main->Button(-text => 'Show Editable List Report',
			-command =>
			sub
			{
			$l1 = $main->ReportBox(
				-title => 'Head',
				-file => 'test.rp',
				-mode => 1,
				-headers => 2
				);
			}
			)->pack();

my $but2 = $main->Button(-text => 'Show Static TextReport',
			-command =>
			sub
			{
			$l1 = $main->ReportBox(
				-title => 'Head',
				-file => 'test.rp',
				-mode => 0,
				);
			}
			)->pack();

my $but1 = $main->Button(-text => 'Show return from ReportBox',
			-command =>
			sub
			{
			my $result = $l1->deliver();
			if ($result)
				{
				$l4->configure(-text => "$result");
				}
			else
				{
				$l4->configure(-text => "nada");
				}
			}
			)->pack();
$l4 = $main->Label()->pack();


MainLoop;

#-------------------------------------------------

