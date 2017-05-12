#! /usr/bin/perl

use Tk::TabFrame;
use Tk::ComboEntry;
use Tk::CheckBox;
use Tk;

my $l_MainWindow = MainWindow->new();

my $l_Window = $l_MainWindow->TabFrame (-font => '-adobe-times-medium-r-normal--20-*-*-*-*-*-*-*')->pack (-expand => true, -fill => both);

my ($l_Frame1) = $l_Window->Frame (-caption => 'Caption One', -tabcolor => 'yellow');
my ($l_Frame2) = $l_Window->Frame (-caption => 'This is Caption Two');
my ($l_Frame3) = $l_Window->Frame (-caption => '3', -tabcolor => 'blue');

$l_Frame1->Entry (-width => 24, -font => '7x14')->pack();
$l_Frame1->Entry (-width => 10, -font => '7x14')->pack();

$l_Frame2->Entry (-width => 32, -font => '7x14')->pack(-anchor => 'nw', -side => 'top');
$l_Frame2->Entry (-width => 12, -font => '7x14')->pack(-anchor => 'nw', -side => 'top');
$l_Frame2->Entry (-width => 9, -font => '7x14')->pack(-anchor => 'nw', -side => 'top');
$l_Frame2->Entry (-width => 3, -font => '7x14')->pack(-anchor => 'nw', -side => 'top');

$l_Frame3->Entry (-width => 3, -font => '7x14')->pack(-anchor => 'nw', -side => 'top');
$l_Frame3->ComboEntry (-width => 23, -itemlist => [`ls /`])->pack(-anchor => 'nw', -side => 'top');
$l_Frame3->ComboEntry (-width => 43, -itemlist => [`ls /`])->pack(-anchor => 'nw', -side => 'top');
$l_Frame3->CheckBox()->pack (-anchor => 'nw', -side => 'top');

my $l_ButtonFrame = $l_MainWindow->Frame();

my $l_OK = $l_ButtonFrame->Button
   (
    -text => Ok,

    -command => sub
       {
        printf ("Values=[%s]\n", join ('|', $l_Frame4->Query()));
        $l_MainWindow->destroy();
       }
   );

$l_OK->pack
   (
    -side => right,
    -anchor => 'ne',
    -fill => 'none',
    -padx => 10,
   );

my $l_Cancel = $l_ButtonFrame->Button
   (
    -text => Cancel,
    -command => sub {$l_MainWindow->destroy();}
   );

$l_Cancel->pack
   (
    -side => left,
    -anchor => 'nw',
    -fill => 'none',
    -padx => 10,
   );

$l_ButtonFrame->pack
   (
    -side => bottom,
    -anchor => 's',
    -fill => 'none',
    -pady => 10,
   );

Tk::MainLoop();