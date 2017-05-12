# Simple demo for Tk::NumKeypad
# (c)2010 by Steve Roscio.
# This program is free software, you can redistribute it and/or modify it
#  under the same terms as Perl itself.

use strict;
use Tk;
use Tk::NumKeypad; 

my $mw = new MainWindow(-title => "Tk::NumKeypad Demo");
my $e  = $mw->Entry->pack;
$mw->NumKeypad(-entry=>$e)->pack; 
$e->focus;
MainLoop;
