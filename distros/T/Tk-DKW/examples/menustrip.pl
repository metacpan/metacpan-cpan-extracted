#! /usr/bin/perl

use Tk::Menustrip;

my $l_MainWindow = MainWindow->new();

my $l_Menubar = $l_MainWindow->Menustrip();

$l_Menubar->MenuLabel ('File');
$l_Menubar->MenuEntry ('File', 'This is a test');
$l_Menubar->MenuEntry ('File', 'Stop');
$l_Menubar->MenuEntry ('File', 'Disable All', sub {$l_Menubar->DisableEntry ('File', 'Stop');});
$l_Menubar->MenuEntry ('File', 'Exit', sub {$l_MainWindow->destroy();});

$l_Menubar->MenuLabel ('Project');
$l_Menubar->MenuEntry ('Project', 'Make');
$l_Menubar->MenuSeparator ('Project');
$l_Menubar->MenuEntry ('Project', 'Run');

$l_Menubar->MenuLabel     ('Help', '-right');
$l_Menubar->MenuEntry     ('Help', 'About...');
$l_Menubar->MenuSeparator ('Help');
$l_Menubar->MenuEntry     ('Help', 'Help On...');

$l_Menubar->pack(-fill => x);

$l_MainWindow->geometry ('300x50');

Tk::MainLoop;