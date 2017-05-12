#!perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib $Bin . '/../lib'; # find module in distro folder structure so you don't have to install it
use Tk;
use Tk::FcyEntry;
my $mw = Tk::MainWindow->new(-title=>'FcyEntry Example');
my $e = $mw->Entry->grid;    # is a FcyEntry, eh, eh :-)
$e->insert(0, 'change state please');



my $state = 'normal';
my $r1 = $mw->Radiobutton(
			-text=>'normal',
			-variable=>\$state,
			-value=>'normal',
			-command=>sub{$e->configure(-state=>'normal')},
			)->grid;
my $r2 = $mw->Radiobutton(
			-text=>'disabled',
			-variable=>\$state,
			-value=>'disabled',
			-command=>sub{$e->configure(-state=>'disabled')},
			)->grid;

Tk::MainLoop;
