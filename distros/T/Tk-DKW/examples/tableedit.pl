#! /usr/bin/perl

use Tk;

use Tk::TableEdit;
use Tk::ComboEntry;
use Tk::CheckBox;

my $l_MainWindow = MainWindow->new();

my $l_Window = $l_MainWindow->TableEdit
   (
    '-file' => 'test.dat',
   );

$l_Window->Item
   (
    'Entry',
    '-name' => 'Date',
    '-default' => sub {localtime();},
   );

$l_Window->Item
   (
    'ComboEntry',
    '-bg' => 'white',
    '-relief' => 'sunken',
    '-section' => 'Global',
    '-name' => 'Now What',
    '-list' => [qw (This is a very big test)],
    '-state' => 'normal',
    '-width' => 20,
   );

$l_Window->Item
   (
    'Entry',
    '-name' => 'New Date',
    '-section' => 'Global',
    '-default' => sub {localtime();},
   );

$l_Window->Item
   (
    'Entry',
    '-bg' => 'white',
    '-relief' => 'sunken',
    '-name' => 'Internet Address',

    '-expression' =>
       [
        '^[0-9]{1,3}?$',
        '^[0-9]{1,3}?\.$',
        '^[0-9]{1,3}?\.[0-9]{1,3}?$',
        '^[0-9]{1,3}?\.[0-9]{1,3}?\.$',
        '^[0-9]{1,3}?\.[0-9]{1,3}?\.[0-9]{1,3}?$',
        '^[0-9]{1,3}?\.[0-9]{1,3}?\.[0-9]{1,3}?\.$',
        '^[0-9]{1,3}?\.[0-9]{1,3}?\.[0-9]{1,3}?\.[0-9]{1,3}?$',
       ],
   );

$l_Window->pack ('-expand' => 'true', '-fill' => 'both');
$l_Window->GeometryRequest (400, 200);
Tk::MainLoop();