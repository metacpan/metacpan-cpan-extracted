# Simple demo for Tk::DoCommand
# (c)2010 by Steve Roscio.
# This program is free software, you can redistribute it and/or modify it
#  under the same terms as Perl itself.

use strict;
use Tk;
use Tk::DoCommand; 

my $mw = new MainWindow(-title => "Tk::DoCommand Demo");
my $dc = $mw->DoCommand(-command => "ls -al; sleep 3; pwd")->pack;
$dc->start_command;
MainLoop;
