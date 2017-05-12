#!/usr/bin/perl -w

use strict;
use FindBin;
use Test::More;

use Tk;
use Tk::JPEG::Lite;

my $file = (@ARGV) ? shift : "$FindBin::RealBin/testimg.jpg";

my $mw = eval { Tk::MainWindow->new() };
if (!Tk::Exists($mw)) {
    plan skip_all => "Cannot create MainWindow: $@";
    CORE::exit(0);
}

plan tests => 1;

$mw->geometry('+10+10');
my $image = $mw->Photo('-format' => 'jpeg', -file => $file);
$mw->Label(-image => $image)->pack;
pass 'Loaded and display image';
$mw->update;
$mw->after(500,[destroy => $mw]);
MainLoop;
