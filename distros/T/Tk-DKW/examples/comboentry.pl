#! /usr/bin/perl

use Tk::ComboEntry;
use Tk;

my $l_MainWindow = MainWindow->new();

my $l_Window = $l_MainWindow->ComboEntry
   (
    '-invoke' => sub {$_[0]->configure ('-bg' => 'grey'); printf ("[%s]\n", join ('|', (@_, $_[0]->get())));},
    '-list' => [qw (this is a very large and important test)],
    '-font' => '-Adobe-Times-Medium-r-Normal--*-180-*-*-*-*-*-*',
    '-listfont' => '-Adobe-Times-Medium-I-Normal--*-140-*-*-*-*-*-*',
    '-selectmode' => 'extended',
    '-background' => 'white',
    '-listheight' => 60,
    '-showmenu' => 1,
   );

$l_Window->delete ('0', 'end');
$l_Window->insert ('0', 'This is a test');

$l_Window->pack
   (
    '-expand' => 'true',
    '-fill' => 'both',
   );

$l_MainWindow->GeometryRequest (400, 200);
Tk::MainLoop();