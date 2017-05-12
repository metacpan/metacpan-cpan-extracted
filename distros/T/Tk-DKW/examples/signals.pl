#! /usr/bin/perl

package Tk::MyWindow;

use Tk::Signals;
use Tk::Button;
use Tk::Frame;
use Tk;

use base qw (Tk::Frame Tk::Signals);

Tk::Widget->Construct ('MyWindow');

sub Populate
   {
    my $this = shift;

    $this->SUPER::Populate (@_);

    $this->Component ('Entry' => 'Entry', '-relief' => 'sunken')->pack ('-expand' => 'true', '-fill' => 'both');

    $this->GLOBALSLOT ('MySignal');
    $this->SLOT ('LocalSignal');

    return $this;
   }

sub MySignal
   {
    $_[0]->Subwidget ('Entry')->delete (0, 'end');

    $_[0]->Subwidget ('Entry')->insert
       (
        0,
        sprintf ("Object [%s] called [%s] with signal MySignal and parameter [%s]", $_[1], $_[0], $_[2])
       );
   }

sub LocalSignal
   {
    $_[0]->Subwidget ('Entry')->insert
       (
        0,
        sprintf ("Object [%s] called [%s] with signal LocalSignal and parameter [%s]", $_[1], $_[0], $_[2])
       );
   }

1;

package Main;

use Tk;

my $l_MainWindow = Tk::MainWindow->new();

foreach my $l_Toplevel ($l_MainWindow, $l_MainWindow->Toplevel(), $l_MainWindow->Toplevel())
   {
    my $l_Window = $l_Toplevel->MyWindow()->pack ('-expand' => 'true', '-fill' => 'both', '-anchor' => 'nw');
    $l_Window->Label ('-text' => sprintf ("Object [%s]", $l_Window), '-bg' => 'white')->pack ('-expand' => 'true', '-fill' => 'x', '-anchor' => 'nw');
    $l_Window->Button ('-command' => sub {$l_Window->SIGNAL ('LocalSignal', $l_Window);}, '-text' => 'LocalSignal')->pack ('-anchor' => 'nw', '-side' => 'left');
    $l_Window->Button ('-command' => sub {$l_Window->SIGNAL ('MySignal', $l_Window);}, '-text' => 'MySignal')->pack('-anchor' => 'nw', '-side' => 'right');
    $l_Toplevel->geometry ('750x170');
   }

Tk::MainLoop();

