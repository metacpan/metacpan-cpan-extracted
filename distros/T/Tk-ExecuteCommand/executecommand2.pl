#!/usr/local/bin/perl -w
use Tk;
use lib './blib/lib'; use Tk::ExecuteCommand;
use strict;

my $mw = MainWindow->new;

my $ec = $mw->ExecuteCommand->pack;
$ec->terse_gui;
$ec->configure(-command => 'date; sleep 5; date');
$ec->execute_command;
 
MainLoop;
