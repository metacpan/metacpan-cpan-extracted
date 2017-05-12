$Tk::Calculator::RPN::HP_21::VERSION = '1.2';

package Tk::Calculator::RPN::HP_21;

use Tk::widgets qw/SlideSwitch/;
use Tk::Calculator::RPN::HP;
use base qw/Tk::Calculator::RPN::HP/;
use strict;

our $HELP;

sub ClassInit {

    my ($class, $mw) = @_;

    $HELP = $class->build_help_window($mw);
    $class->SUPER::ClassInit($mw);

} # end ClassInit

sub build_button_rows {

    my ($self, $parent, $button_descriptions) = @_;

    foreach my $row (@$button_descriptions) {
	my $frame = $parent->Frame;
	foreach my $buttons (@$row) {
	    my ($p1, $p2, $color, $func) = @$buttons;

	    $frame->Tk::Calculator::RPN::HP::Key2_21(
                -butl       => $p1,
                -botl       => $p2,
                -background => $color,
                -command    => $func,
            );
	}
	$frame->pack(qw/-side top -expand 1 -fill both/);
	$self->{PB}->set($self->{PB_PERCENT} += 10) if $self->{PB};
    }

} # end build_button_rows

sub Populate {

    my ($self, $args) = @_;

    $self->optionAdd('*background' => $GRAY_LIGHTER);
    $self->{ONOFF}      = 1;   # 1 IFF calculator on (1 initially)
    $self->{RCFILE}     = $^O eq "MSWin32" ?
	'C:\.hp\hp21' : "$ENV{HOME}/.hp/hp21";

    # The LED display.

    my $frame0 = $self->Frame;
    $frame0->Frame(
        -background   => 'black',
        -height       => 7,
    )->pack(qw/-expand 1 -fill x -padx 10/);
    $frame0->pack(qw/-padx 5 -pady 5 -fill both -expand 1/)->pack;
    $frame0->Label(
        -background   => 'black',
        -width        => 25,
        -foreground   => 'red',
        -font         => ['arial', 14, 'bold'],
        -textvariable => \$self->{XV},
        -anchor       => 'w',
    )->pack(qw/-expand 1 -fill x -padx 10/);
    $frame0->Frame(
        -background   => 'black',
        -height       => 7,
    )->pack(qw/-expand 1 -fill x -padx 10/);

    # The two SlideSwitches.

    my $frame1 = $self->Frame(qw/-relief sunken -bd 2/)->pack;
    $frame1->pack(qw/-fill both -expand 1/);
    my $font = ['courier', 10, 'bold'];
    my $sl1 = $frame1->SlideSwitch(
        -bg          => $GRAY_LIGHTER,
	-orient      => 'horizontal',
        -command     => [$self => 'on'],
        -llabel      =>
         [-text => 'OFF', -fg => 'black', -bg => $GRAY_LIGHTER, -font => $font],
        -rlabel      =>
         [-text => 'ON',  -fg => 'black', -bg => $GRAY_LIGHTER, -font => $font],
        -troughcolor => $GRAY_LIGHTER,
    )->pack(qw/-side left -expand 1/);

    $self->build_help_button($frame1, $HELP)->pack(qw/-side left/);

    my $sl2 = $frame1->SlideSwitch(
        -bg          => $GRAY_LIGHTER,
	-orient      => 'horizontal',
        -llabel      =>
	 [-text => 'DEG', -fg => 'black', -bg => $GRAY_LIGHTER, -font => $font],
        -rlabel      =>
         [-text => 'RAD', -fg => 'black', -bg => $GRAY_LIGHTER, -font => $font],
        -troughcolor => $GRAY_LIGHTER,
        -variable    => \$self->{MODE},
    )->pack(qw/-side right -expand 1/);

    $self->{PB}->set($self->{PB_PERCENT} += 10) if $self->{PB};
 
    # Build all the button rows.

    my $frame2 = $self->Frame(qw/-relief sunken -bd 4/)->pack;

    build_button_rows $self, $frame2, [
        [
            ['1/x',      'y**x',   $GRAY,   [$self => 'rpexp']],
	    ['SIN',     'SIN-1',   $GRAY,   [$self => 'sinasin']],
            ['COS',     'COS-1',   $GRAY,   [$self => 'cosacos']],
            ['TAN',     'TAN-1',   $GRAY,   [$self => 'tanatan']],
            ['g',            '',   $BLUE,   [$self => 'g']],
        ],
        [
            [$SWAP,      '>R',     $GRAY,   [$self => 'swapxy']],
	    [$ROLD,      '>P',     $GRAY,   [$self => 'roll_stack']],
            ['e**x',     'LN',     $GRAY,   [$self => 'exln']],
            ['STO',      'LOG',    $GRAY,   [$self => 'stolog']],
            ['RCL',      '10**x',  $GRAY,   [$self => 'rclt2x']],
        ],
        [
            ['ENTER ^',  '',       $GRAY,   [$self => 'enter']],
	    ['CHS',      'SQRT',   $GRAY,   [$self => 'chssqrt']],
            ['EEX',      $PI,      $GRAY,   [$self => 'eexpi']],
            ['CLx',      'CLR',    $GRAY,   [$self => 'clxclr']],
        ],
        [
            ['-',        'M-',     'tan',   [$self => 'math3', $SB, undef, undef]],
	    ['7',        '',       'tan',   [$self => 'key', 7]],
	    ['8',        '',       'tan',   [$self => 'key', 8]],
	    ['9',        '',       'tan',   [$self => 'key', 9]],
        ],
        [
            ['+',        'M+',     'tan',   [$self => 'math3', $AD, undef, undef]],
	    ['4',        '',       'tan',   [$self => 'key', 4]],
	    ['5',        '',       'tan',   [$self => 'key', 5]],
	    ['6',        '',       'tan',   [$self => 'key', 6]],
        ],
        [
            ['x',        'Mx',     'tan',   [$self => 'math3', $ML, undef, undef]],
	    ['1',        '',       'tan',   [$self => 'key', 1]],
	    ['2',        '',       'tan',   [$self => 'key', 2]],
	    ['3',        '',       'tan',   [$self => 'key', 3]],
        ],
        [
            ['/',        'M/',     'tan',   [$self => 'math3', $DV, undef, undef]],
	    ['0',        '',       'tan',   [$self => 'key', 0]],
	    ['.',        '',       'tan',   [$self => 'key', '.']],
	    ['DSP',      '',       'tan',   [$self => 'err']],
        ],
    ];

    # The Quit Button and HP logo.

    my $frame3 = $self->Frame->pack;
    $font = ['courier', 10, 'bold'];
    my $hp = $frame3->Button(
        -text    => ' hp ',
        -font    => $font,
        -relief  => 'raised',
        -command => sub {
            $self->{ONOFF} = 1;
            $self->on;
            &Tk::exit;
        },
    );
    $hp->pack(qw/-side left -expand 1 -fill both -pady 10/);
    $hp->bind('<Enter>' => sub {$_[0]->configure(-text => 'Quit')});
    $hp->bind('<Leave>' => sub {$_[0]->configure(-text => ' hp ')});
    $frame3->Label(
        -text       => ' H E W L E T T . P A C K A R D 21',
        -font       => $font,
        -foreground => $SILVER,
        -background => $GRAY_LIGHTER,
    )->pack(qw/-side left -expand 0/);

    $self->set_keypad_bindings;
  
    $self->{PB}->set($self->{PB_PERCENT} = 90) if $self->{PB};
 
} # end Populate

# Function key processors.

sub chssqrt {

    my ($self) = @_;

    return unless $self->{ONOFF};
    if ($self->{G_PRESSED}) {	# sqrt
	$self->math($SQ);
    } else {			# chs
	$self->chs;
    }

} # end chssqrt

sub clxclr {

    my ($self) = @_;

    return unless $self->{ONOFF};
    if ($self->{G_PRESSED}) {	# clr
	$self->clr;
    } else {			# clx
	$self->clx;
    }

} # end clxclr

sub cosacos {

    my ($self) = @_;

    return unless $self->{ONOFF};
    if ($self->{G_PRESSED}) {
	$self->trig_math($AC);
    } else {
	$self->trig_math($CO);
    }

} # end cosacos

sub eexpi {

    my ($self) = @_;

    return unless $self->{ONOFF};
    if ($self->{G_PRESSED}) {
	$self->pi;
    } else {
	$self->err;
    }

} # end eexpi

sub exln {

    my ($self) = @_;

    return unless $self->{ONOFF};
    my $f = $self->{G_PRESSED} ? $LN : $EX;
    $self->math($f);

} # end exln

sub on {

    my ($self, $val) = @_;

    return unless defined $val;
    $self->clr;
    $self->SUPER::on($val);

} # end on

sub rclt2x {

    my ($self) = @_;

    return unless $self->{ONOFF};
    if ($self->{G_PRESSED}) {
	$self->math($TX);
    } else {
	$self->err;
    }

} # end rclt2x

sub rpexp {

    my ($self) = @_;

    return unless $self->{ONOFF};
    if ($self->{G_PRESSED}) {
	$self->math3(undef, undef, $YX);
    } else {
	$self->math($RP);
    }

} # end rpexp

sub roll_stack {

    my ($self) = @_;

    return unless $self->{ONOFF};
    if ($self->{G_PRESSED}) {
	$self->bell;
    } else {
	$self->roll_down;
    }

} # end rollstack

sub sinasin {

    my ($self) = @_;

    return unless $self->{ONOFF};
    if ($self->{G_PRESSED}) {
	$self->trig_math($AS);
    } else {
	$self->trig_math($SI);
    }

} # end sinasin

sub stolog {

    my ($self) = @_;

    return unless $self->{ONOFF};
    if ($self->{G_PRESSED}) {
	$self->math($LG);
    } else {
	$self->err;
    }

} # end stolog

sub tanatan {

    my ($self) = @_;

    return unless $self->{ONOFF};
    if ($self->{G_PRESSED}) {
	$self->trig_math($AT);
    } else {
	$self->trig_math($TA);
    }

} # end tanatan

1;

=head1 AUTHOR

sol0@Lehigh.EDU

Copyright (C) 2001 - 2007, Steve Lidie. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 KEYWORDS

calculator, HP, RPN, HP 21

=cut
