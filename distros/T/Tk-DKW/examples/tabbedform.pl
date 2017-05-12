#! /usr/bin/perl

use Tk::TabbedForm;
use Tk::CheckBox;
use Tk;

my $l_MainWindow = MainWindow->new();

my $l_Window = $l_MainWindow->TabbedForm();

$l_Window->Item
   (
    'Entry',
    '-name' => 'Date',
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

$l_Window->Item
   (
    'Entry',
    '-name' => 'Date',
    '-default' => sub {localtime();},
    '-section' => 'A test',
   );

$l_Window->pack ('-expand' => 'true', '-fill' => 'both');
Tk::MainLoop();
