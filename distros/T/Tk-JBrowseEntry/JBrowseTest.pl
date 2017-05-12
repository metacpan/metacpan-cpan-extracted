#!/usr/bin/perl -s 

eval 'exec /usr/bin/perl -s  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

use lib '.';
use Tk;                   #LOAD TK STUFF
use Tk::BrowseEntry;
use Tk::JBrowseEntry;

$MainWin = MainWindow->new;

$dbname1 = 'cows';
$dbname2 = 'foxes';
$dbname3 = 'goats';
$dbname5 = 'default';

$jb1 = $MainWin->JBrowseEntry(
	-label => 'Normal:',
	-variable => \$dbname1,
	-state => 'normal',
#	-arrowimage => $MainWin->Getimage('balArrow'),
	-choices => [qw(pigs cows foxes goats)],
	-width  => 12);
$jb1->pack(
	-side   => 'top', -pady => '10', -anchor => 'w');
$jb2 = $MainWin->JBrowseEntry(
#	-arrowimage => $MainWin->Getimage('balArrow'),
	-label => 'TextOnly:',
	-variable => \$dbname2,
	-state => 'textonly',
	-choices => [qw(pigs cows foxes goats)],
	-width  => 12);
$jb2->pack(
	-side   => 'top', -pady => '10', -anchor => 'w');
$jb3 = $MainWin->JBrowseEntry(
	-label => 'ReadOnly:',
	-variable => \$dbname3,
	-choices => [qw(pigs cows foxes goats)],
	-state => 'readonly',
	-width  => 12);
$jb3->pack(
	-side   => 'top', -pady => '10', -anchor => 'w');
$jb4 = $MainWin->JBrowseEntry(
	-label => 'Disabled:',
	-variable => \$dbname3,
	-state => 'disabled',
	-choices => [qw(pigs cows foxes goats)],
	-width  => 12);
$jb4->pack(
	-side   => 'top', -pady => '10', -anchor => 'w');
$jb5 = $MainWin->JBrowseEntry(
	-label => 'Scrolled List:',
	-width => 12,
	-default => $dbname5,
	-height => 4,
	-variable => \$dbname5,
	-browsecmd => sub {print "-browsecmd!\n";},
	-listcmd => sub {print "-listcmd!\n";},
	-state => 'normal',
	-choices => [qw(pigs cows foxes goats horses sheep dogs cats ardvarks default)]);
$jb5->pack(
	-side   => 'top', -pady => '10', -anchor => 'w');
$jb6 = $MainWin->JBrowseEntry(
	-label => 'Button Focus:',
	-btntakesfocus => 1,
#	-arrowimage => $MainWin->Getimage('balArrow'),
#	-farrowimage => $MainWin->Getimage('cbxarrow'),
	-width => 12,
	-height => 4,
	-variable => \$dbname6,
	-browsecmd => sub {print "-browsecmd!\n";},
	-listcmd => sub {print "-listcmd!\n";},
	-state => 'normal',
#-borderwidth => 12,
#-framehighlightthickness => 6,
#-entryborderwidth => 8,
#-labelPack => [qw/-side top/],
	-choices => [qw(pigs cows foxes goats horses sheep dogs cats ardvarks default)]);
$jb6->pack(
	-side   => 'top', -pady => '10', -anchor => 'w');
$jb8 = $MainWin->JBrowseEntry(
	-label => 'Button Focus Only:',
	-takefocus => 0,
	-btntakesfocus => 1,
	-width => 12,
	-height => 4,
	-variable => \$dbname6,
	-browsecmd => sub {print "-browsecmd!\n";},
	-listcmd => sub {print "-listcmd!\n";},
	-state => 'normal',
	-choices => [qw(pigs cows foxes goats horses sheep dogs cats ardvarks default)]);
$jb8->pack(
	-side   => 'top', -pady => '10', -anchor => 'w');
$jb7 = $MainWin->JBrowseEntry(
	-label => 'Skip Focus:',
	-takefocus => 0,
	-btntakesfocus => 0,
	-width => 12,
	-height => 4,
	-variable => \$dbname7,
	-browsecmd => sub {print "-browsecmd!\n";},
	-listcmd => sub {print "-listcmd!\n";},
	-state => 'normal',
	-choices => [qw(pigs cows foxes goats horses sheep dogs cats ardvarks default)]);
$jb7->pack(
	-side   => 'top', -pady => '10', -anchor => 'w');

$jb7->choices([qw(First Second Fifth Sixth)]);   #REPLACE LIST CHOICES!
$jb7->insert(2, 'Third', 'Fourth');              #ADD MORE AFTER 1ST 2.
$jb7->insert('end', [qw(Seventh Oops Nineth)]);  #ADD STILL MORE AT END.
$jb7->delete(7);                                 #REMOVE ONE.

$b = $MainWin->Button(-text => 'Quit', -command => sub {exit (0); });
$b->pack(-side => 'top');
 $jb1->focus;

MainLoop;
