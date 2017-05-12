# Simple demo for Tk::FullKeypad
# (c)2010 by Steve Roscio.
# This program is free software, you can redistribute it and/or modify it
#  under the same terms as Perl itself.

use strict;
use Tk;
use Tk::FullKeypad; 

my $mw = new MainWindow(-title => "Tk::FullKeypad Demo");
my $e  = $mw->Entry->pack;
$mw->FullKeypad(-entry=>$e)->pack; 
$e->focus;
MainLoop;
