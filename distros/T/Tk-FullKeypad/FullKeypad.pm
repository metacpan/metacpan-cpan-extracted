#=============================================================================
#
# Full Keypad for Perl/Tk apps.
#
#-----------------------------------------------------------------------------

# one-line test:
#  perl -we 'use strict; use Tk; use Tk::FullKeypad; my $mw=new MainWindow; my $e=$mw->Entry->pack; $mw->FullKeypad(-entry=>$e)->pack; $e->focus; MainLoop;'

package Tk::FullKeypad;
use vars qw/$VERSION/;
$VERSION = '1.0';

use Tk::widgets qw/Button/;
use base qw/Tk::Frame/;
use strict;
use warnings;

Construct Tk::Widget 'FullKeypad';

sub ClassInit {
    my ($class, $mw) = @_;
    $class->SUPER::ClassInit($mw);
}

sub Populate {
    my ($this, $args) = @_;
    $this->SUPER::Populate($args);
    $this->{_caps} = 0;
    $this->{_shift} = 0;

    # Normal keys
    my $span = 4;
    my $row  = 0;
    $this->_putrow(0, $row++, $span, qw:~` !1 @2:, '#3', qw:$4 %5 ^6 &7 *8 (9 )0 _- += :);
    $this->_putrow(1, $row++, $span, qw*   Q  W  E  R  T  Y  U  I  O  P {[ }] |\       *);
    $this->_putrow(1, $row++, $span, qw*   A  S  D  F  G  H  J  K  L :; "'             *);
    $this->_putrow(1, $row++, $span, qw*   Z  X  C  V  B  N  M*, '<,', qw* >. ?/       *);

    # Specialty keys
    my $kpback = $this->Button(
        -text    => "Backspace\n\x{21d0}",
        -command => sub {$this->_backspace}
        )->grid(
        -row        => 0,
        -column     => 52 + 0,
        -columnspan => $span,
        -sticky     => 'nsew'
        );
    $this->Advertise("KPBack" => $kpback);
    my $kpenter = $this->Button(
        -text    => "Enter\n\x{21b5}",
        -command => sub {$this->_padpress("\n")}
        )->grid(
        -row        => 2,
        -column     => 48 + 2,
        -columnspan => 2 * $span,
        -sticky     => 'nsew'
        );
    $this->Advertise("KPEnter" => $kpenter);
    my $kpspace = $this->Button(
        -text    => "Space",
        -command => sub {$this->_padpress(q{ });}
        )->grid(
        -row        => 3,
        -column     => 44 + 3,
        -columnspan => 1.5 * $span,
        -sticky     => 'nsew'
        );
    $this->Advertise("KP " => $kpspace);
    $this->Advertise("KPSpace" => $kpspace);
    my $kpshift
        = $this->Button(-text => "Shift", -command => sub {$this->_shift})
        ->grid(
        -row        => 3,
        -column     => 50 + 3,
        -columnspan => 1.5 * $span,
        -sticky     => 'nsew'
        );
    $this->Advertise("KPShift" => $kpshift);

    # More specialty keys
    $this->Label(-text=> q{ })->grid(-row => 0, -column => 59); # make a gap

    my $kpcaps = $this->Button(
        -text    => "Caps\nLock",
        -command => sub {$this->_caps}
        )->grid(
        -row        => 2,
        -column     => 0,
        -columnspan => 1.5*$span,
        -sticky     => 'nsew'
        );
    $this->Advertise("KPCaps" => $kpcaps);
    my $kpdel = $this->Button(
        -text    => "Delete",
        -command => sub {$this->_delete}
        )->grid(
        -row        => 0,
        -column     => 60,
        -columnspan => $span,
        -sticky     => 'nsew'
        );
    $this->Advertise("KPDel" => $kpdel);
    my $kpleft = $this->Button(
        -text    => "\x{2190}",
        -command => sub {$this->_arrow(-1)}
        )->grid(
        -row        => 1,
        -column     => 60,
        -columnspan => $span,
        -sticky     => 'nsew'
        );
    $this->Advertise("KPLeft" => $kpleft);
    my $kpright = $this->Button(
        -text    => "\x{2192}",
        -command => sub {$this->_arrow(1)}
        )->grid(
        -row        => 2,
        -column     => 60,
        -columnspan => $span,
        -sticky     => 'nsew'
        );
    $this->Advertise("KPRight" => $kpright);
    my $kpclr = $this->Button(
        -text    => "Clear",
        -command => sub {$this->_clear}
        )->grid(
        -row        => 3,
        -column     => 60,
        -columnspan => $span,
        -sticky     => 'nsew'
        );
    $this->Advertise("KPClear" => $kpclr);

    $this->ConfigSpecs(
        -entry    => ['PASSIVE'],
        'DEFAULT' => ['DESCENDANTS']
    );
    return $this;
}

sub _arrow {
    my ($this, $n) = @_;
    my $e = $this->cget('-entry');
    return if !$e;
    $e->icursor($e->index('insert') + $n);
}

sub _backspace {
    my ($this) = @_;
    my $e = $this->cget('-entry');
    return if !$e;
    if ($e->selectionPresent) {
        return $e->delete('sel.first', 'sel.last');
    }
    my $i = $e->index('insert');
    return if $i <= 0;
    return $e->delete($i-1);
}

sub _caps {
    my $this = shift;
    $this->{_caps} = !$this->{_caps};
    my $kpcaps = $this->Subwidget("KPCaps");
    $kpcaps->configure(-text => $this->{_caps} ? "CAPS\nLOCK" : "Caps\nLock");
}

sub _clear {
    my ($this) = @_;
    my $e = $this->cget('-entry');
    return if !$e;
    return $e->delete(0, 'end');
}

sub _delete {
    my ($this) = @_;
    my $e = $this->cget('-entry');
    return if !$e;
    if ($e->selectionPresent) {
        return $e->delete('sel.first', 'sel.last');
    }
    return $e->delete($e->index('insert'));
}

sub _padpress {
    my ($this, $n) = @_;
    my $e = $this->cget('-entry');
    return if !$e;
    if ($e->selectionPresent) {
        $e->delete('sel.first', 'sel.last');
    }
    if (length($n) > 1) {
        $e->insert('insert',
            $this->{_shift} ? substr($n, 0, 1) : substr($n, 1, 1));
    }
    else {
        $e->insert('insert', ($this->{_shift} xor $this->{_caps})? uc $n : lc $n);
    }
}

sub _putrow {
    my ($this, $i, $row, $span, @keys) = @_;
    foreach my $key (@keys) {
        my $txt
            = length($key) > 1
            ? q{ } . substr($key, 0, 1) . " \n " . substr($key, 1, 1) . q{ }
            : " $key ";
        my $btn = $this->Button(
            -text    => $txt,
            -command => sub {$this->_padpress($key);},
            )->grid(
            -row        => $row,
            -column     => $i * $span + $row,
            -columnspan => $span,
            -sticky     => 'nsew'
            );
        $this->Advertise("KP$key" => $btn);
        ++$i;
    }
}

sub _shift {
    my $this = shift;
    $this->{_shift} = !$this->{_shift};
    my $kpshift = $this->Subwidget("KPShift");
    $kpshift->configure(-text => $this->{_shift} ? "SHIFT" : "Shift");
}

__END__

=head1 NAME

Tk::FullKeypad - A full alphanumeric keypad widget

=head1 SYNOPSIS

    my $e = $mw->Entry(...)->pack;   # Some entry widget
    my $kp = $mw->FullKeypad(-entry => $e)->pack;  # This keypad

=head1 DESCRIPTION

A full US keyboard as a keypad.  This is useful for touchscreen or
kiosk applications where access to a real keyboard won't be available.

The keypad is arranged as follows (this is a rough approximation,
it looks better when rendered):

    ~` !1 @2 #3 $4 %5 ^6 &7 *8 (9 )0 _- += Backspace Delete
        Q  W  E  R  T  Y  U  I  O  P {[ }] |\         <--
    Caps A  S  D  F  G  H  J  K  L :; "'       Enter  -->
          Z  X  C  V  B  N  M  <, >. ?/  Space Shift Clear


The widget is designed to supply values to an Entry widget.
Specify the Entry widget with the -entry option.

The Enter key currently does nothing (what should it do?)
The Clear key will clear the contents of the associated Entry widget,
regardless of if a slectedion is present or not.

The Shift key is "sticky". Press it once to shift to uppercase letters
or the characters on the top of the keys; press again to go to lowercase.
The key's lable changes from "Shift" to "SHIFT" to indicate the mode.

The Caps Lock key is also sticky.  It changes from "Caps Lock" to "CAPS LOCK"
to inidicate its mode.  When enabled, it inverts the meaning of Shift for
the alphabetic keys A thru Z.

The following options/value pairs are supported:

=over 4

=item B<-entry>

Identifies the associated Tk::Entry widget to be populated or cleared
by this keypad.

=back

=head1 METHODS

None.

=head1 ADVERTISED SUBWIDGETS

The individual buttons are advertised as "KP" + the button label
For example, KPA KPB ... KPZ KP. KP, KP; KP< KP>  and so on.
For the specialty keys:
  Clear         KPClear
  Left Arrow    KPLeft
  Right Arrow   KPRight
  Delete        KPDel
  Backspace     KPBack
  Shift         KPShift
  Space         KPSpace and also "KP "
  Enter         KPEnter
  Caps Lock     KPCaps

=head1 AUTHOR

Steve (at) HauntedMines (dot) org

Copyright (C) 2010. Steve Roscio.  All rights reserved.

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 KEYWORDS

FullKeypad

=cut
