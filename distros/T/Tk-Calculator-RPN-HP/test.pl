#!/usr/local/bin/perl -w
use Tk;
use Tk::Calculator::RPN::HP;
use strict;

my $mw = MainWindow->new;
$mw->title('HP 21');
my $c = $mw->Calculator(-type => '21')->pack;;
$mw->update;
$mw->after(2000);
$c->destroy;
$mw->title('HP 16c');
$c = $mw->Calculator(-type => '16c')->pack;;
$mw->update;
$mw->after(2000);
print "Okay.\n";
