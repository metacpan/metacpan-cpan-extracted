#!perl

use strict;
use warnings;
use utf8;
use FindBin qw/$Bin/;
use lib $Bin . '/../lib'; # for testing in dist folder
use Tk;
use Tk::SimpleFileSelect;

my $mw = Tk::MainWindow->new;
$mw->packPropagate(0);
$mw->geometry('640x480');


my $selected_file = 'no file selected so far';
my $label = $mw->Label(-textvariable => \$selected_file)->pack;

my $button = $mw->Button(
    -text => 'open SimpleFileSelect dialog',
    -command => sub{
        my $fs = $mw->SimpleFileSelect();
        my $file = $fs->Show();
        $selected_file = "selected file: " . ($file ? $file : 'no file selected');
        $fs->destroy();
    }
)->pack;

$mw->MainLoop();