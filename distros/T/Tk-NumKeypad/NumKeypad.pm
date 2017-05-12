#=============================================================================
#
# Numeric Keypad for Perl/Tk
#
#-----------------------------------------------------------------------------

package Tk::NumKeypad;
use vars qw/$VERSION/;
$VERSION = '1.4';

use Tk::widgets qw/Button/;
use base qw/Tk::Frame/;
use strict;
use warnings;

Construct Tk::Widget 'NumKeypad';

sub ClassInit {
    my ($class, $mw) = @_;
    $class->SUPER::ClassInit($mw);
}

sub Populate {
    my ($this, $args) = @_;
    $this->SUPER::Populate($args);
    $this->ConfigSpecs(
        -entry    => ['PASSIVE', 'entry',  'Entry',  undef],
        -keysub   => ['PASSIVE', 'keysub', 'Keysub', {}],
        -keyval   => ['PASSIVE', 'keyval', 'Keyval', {}],
        -math     => ['PASSIVE', 'math',   'Math',   0],
        -text     => '-entry',
        'DEFAULT' => ['DESCENDANTS']
    );

    # Keypad
    my $i = 0;
    my $math = $args->{-math};
    my $width = $math ? 4 : 3;
    my $keysub = $args->{-keysub};
    my @keymap = $math ? qw{7 8 9 / 4 5 6 * 1 2 3 - . 0 C +} : qw{7 8 9 4 5 6 1 2 3 . 0 C};
    foreach my $n (@keymap) {
        my $btn = $this->Button(
            -text    => defined $keysub->{$n}? $keysub->{$n} : $n,
            -command => sub {$this->_padpress($n);},
            )->grid(
            -row    => int($i / $width),
            -column => $i % $width,
            -sticky => 'nsew'
            );
        $this->Advertise("KP$n" => $btn);
        ++$i;
    }
    return $this;
}

sub _padpress {
    my ($this, $n) = @_;
    my $e = $this->cget('-entry');
    return if !$e;

    my $defval = {'C' => 'CLEAR'};
    my $keyval = $this->cget('-keyval');
    my $v = defined $keyval->{$n}? $keyval->{$n} : $defval->{$n} || $n;

    if ($e->isa("Tk::Entry")) {

        # Entry widget
        return ($e->index('insert') > 0) && $e->delete($e->index('insert')-1)
            if $v eq 'BACKSPACE';
        return $e->delete(0, 'end')
            if $v eq 'CLEAR';
        return $e->delete('insert')
            if $v eq 'DELETE';
        $e->delete('sel.first', 'sel.last')
            if $e->selectionPresent;
    }
    else {

        # Text widget
        return ($e->index('insert') gt '1.0') && $e->delete('insert-1 chars')
            if $v eq 'BACKSPACE';
        return $e->delete('1.0', 'end')
            if $v eq 'CLEAR';
        return $e->delete('insert')
            if $v eq 'DELETE';
        $e->delete('sel.first', 'sel.last')
            if $e->tagRanges('sel');
    }

    $e->insert('insert', $v);
}

__END__

=head1 NAME

Tk::NumKeypad - A Numeric Keypad widget

=head1 SYNOPSIS

    my $e = $mw->Entry(...)->pack;   # Some entry or text widget
    my $nkp = $mw->NumKeypad(-entry => $e)->pack;  # Numeric keypad

=head1 DESCRIPTION

A numeric keypad, including a clear button and a decimal point button.
This is useful for touchscreen or kiosk applications where access to a 
keyboard won't be available.

Math keys may be included too; and you may substitute other characters
for the default keys.

The keypad is arranged as follows:

    7 8 9           7 8 9 /
    4 5 6     or    4 5 6 *
    1 2 3           1 2 3 -
    . 0 C           . 0 C +

The widget is designed to supply values to a Tk::Entry or Tk::Text widget.
Specify the Tk::Entry or Tk::Text widget with the -entry option.

The following options/value pairs are supported:

=over 4

=item B<-entry>

Identifies the associated Tk::Entry or Tk::Text widget to be populated or cleared
by this keypad.

=item B<-keysub>

Provide a hashref of substitution strings for the labels on the button keys.
For example, to change the 'C' (clear) key to an 'X':

  -keysub => {'C' => 'X'}

The keys still return their original values, unless you also use -keyval.

=item B<-keyval>

Provide a hashref of alternate values to provide for keys, that's put into your
Tk::Entry or Tk::Text widget.  For example,

  -keyval => {'1' => 'one '}

Note that the special values 'BACKSPACE', 'CLEAR', and 'DELETE'.
'BACKSPACE' will delete one character back from the current cursor position.
'CLEAR' will clear the contents of your text or entry widget.
'DELETE' will delet the character at (after) the current cursor position.

By default, the 'C' key is associated with the 'CLEAR' action.

A popular modification of this KeyPad widget is to change the dot (.) key
into a backspace key, like this:

   -keysub => {'.' => "\x{21d0}"},  # this is the double-line left arrow symbol
   -keyval => {'.' => 'BACKSPACE'},


=item B<-math>

If true, the mathematics keys / (divide), * (multiply), - (subtraction),
and + (addition) are included in the keypad.

=item B<-text>

Alias for -entry.  Use of -text is preferred if the widget really is a Tk::Text.

=back

=head1 METHODS

None.

=head1 ADVERTISED SUBWIDGETS

The individual buttons are advertised as "KP" + the default button label.
They are KP0, KP1, ... KP9, KP. and KPC .
With -math enabled, there are also KP/ KP* KP- and KP+ subwidgets.
These subwidget names do not change when you substitute key labels or values.

=head1 AUTHOR

Steve Roscio  C<< <roscio@cpan.org> >>

Copyright (c) 2010-2012, Steve Roscio C<< <roscio@cpan.org> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

Because this software is licensed free of charge, there is no warranty
for the software, to the extent permitted by applicable law.  Except when
otherwise stated in writing the copyright holders and/or other parties
provide the software "as is" without warranty of any kind, either
expressed or implied, including, but not limited to, the implied
warranties of merchantability and fitness for a particular purpose.  The
entire risk as to the quality and performance of the software is with
you.  Should the software prove defective, you assume the cost of all
necessary servicing, repair, or correction.

In no event unless required by applicable law or agreed to in writing
will any copyright holder, or any other party who may modify and/or
redistribute the software as permitted by the above licence, be
liable to you for damages, including any general, special, incidental,
or consequential damages arising out of the use or inability to use
the software (including but not limited to loss of data or data being
rendered inaccurate or losses sustained by you or third parties or a
failure of the software to operate with any other software), even if
such holder or other party has been advised of the possibility of
such damages.

=head1 KEYWORDS

NumKeypad

=cut

