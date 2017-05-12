$Tk::Calculator::RPN::HP_16C::VERSION = '1.2';

package Tk::Calculator::RPN::HP_16C;

use Tk::widgets qw/Compound Frame ROText/;
use Tk::Calculator::RPN::HP;
use Tk::LCD 1.2;
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
	my $frame = $parent->Frame(-background => $GRAY_LIGHTEST);
	foreach my $buttons (@$row) {
	    my ($p1, $p2, $p3, $color, $func) = @$buttons;

	    $frame->Tk::Calculator::RPN::HP::Key3_16C(
		-topl       => $p2,
                -butl       => $p1,
                -botl       => $p3,
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

    $self->{RCFILE}     = $^O eq "MSWin32" ?
	'C:\.hp\hp16c' : "$ENV{HOME}/.hp/hp16c";

    $self->on; $self->on;	# on/off kluge to initialize HP stack

    # LED display, help button, and HP logo.

    my $tf = $self->Frame(-background => $SILVER);
    $tf->pack(qw/-side top -fill both -expand 1/);

    my $lcdbg = 'honeydew4';
    my $lcdf = $tf->Frame(
        -relief       => 'sunken',
        -borderwidth  => 10, 
        -background   => $lcdbg,
    )->pack(qw/-side left -expand 1 -fill x -padx 70/);

    $self->build_help_button($tf, $HELP)->pack(qw/-side left/);

    $lcdf->LCD(
        -background         => $lcdbg,
        -elements           => 1 + 10,
        -highlightthickness => 0,
        -offfill            => $lcdbg,
        -offoutline         => $lcdbg,
        -onfill             => 'black',
        -onoutline          => 'black',
        -size               => 'small',
        -variable           => \$self->{XV},
    )->pack;

    my $model = " hp \n--\n16C";
    my $hp = $tf->Button(
        -text    => $model,
        -relief  => 'raised',
        -command => sub {
            $self->{ONOFF} = 1;
            $self->on;
            &Tk::exit;
        },
    );
    $hp->pack(qw/-side right -expand 1 -fill both -padx 20 -pady 10/);
    $hp->bind('<Enter>' => sub {$_[0]->configure(-text => "Quit\n--\n16C")});
    $hp->bind('<Leave>' => sub {$_[0]->configure(-text => $model)});

    $self->{PB}->set($self->{PB_PERCENT} += 10) if $self->{PB};

    # Horizontal black and silver lines + vertical left/right silver lines.

    $self->Frame(qw/-background black -height 10/)->pack(qw/-fill x -expand 1/);
    $self->Frame(-bg => $SILVER, -height => 5)->pack(qw/-fill x -expand 1/);

    my $frame0 = $self->Frame(-background => $GRAY_LIGHTEST);
    $frame0->pack(qw/-side top   -fill both -expand 1/);

    $frame0->Frame(-width => 5, -bg => $SILVER)->
        pack(qw/-side left -expand 1 -fill y/);
    $frame0->Frame(-width => 5, -bg => $SILVER)->
        pack(qw/-side right -expand 1 -fill y/);

    # These frames hold all the calculator keys.

    my $frame1 = $frame0->Frame->pack(qw/-side top   -fill both -expand 1/);
    my $frame2 = $frame0->Frame->pack(qw/-side left  -fill both -expand 1/);
    my $frame3 = $frame0->Frame->pack(qw/-side right -fill both -expand 1/);

    # Bottom finishing detail.

    $self->Frame(
        -background => $SILVER,
        -width      => 20,
        -height     => 25,
    )->pack(qw/-side left -expand 0/);   
    $self->Label(
        -text       => ' H E W L E T T . P A C K A R D ',
        -font       => ['courier', 14, 'bold'],		       
        -foreground => $SILVER,
        -background => $GRAY_LIGHTEST,
    )->pack(qw/-side left -expand 0/);
    $self->Frame(
        -background => $SILVER,
        -height     => 25,
    )->pack(qw/-side left -expand 1 -fill x/);   

    $self->Frame(
        -background => $SILVER,
	-width      => 5,
        -height     => 25,
    )->pack(qw/-side left -expand 0/);   

    $self->{PB}->set($self->{PB_PERCENT} += 10) if $self->{PB};

    # Build the first 2 rows of the calculator, 10 calculator keys per row.

    build_button_rows $self, $frame1, [
        [
            ['A',   'SL',      'LJ',   $GRAY,   [$self => 'err']],
	    ['B',   'SR',      'ASR',  $GRAY,   [$self => 'err']],
            ['C',   'RL',      'RLC',  $GRAY,   [$self => 'err']],
            ['D',   'RR',      'RRC',  $GRAY,   [$self => 'err']],
            ['E',   'RLn',     'RLCn', $GRAY,   [$self => 'err']],
            ['F',   'RRn',     'RRCn', $GRAY,   [$self => 'err']],
            ['7',   'MASKL',   '#B',   $GRAY,   [$self => 'key', 7]],
            ['8',   'MASKR',   'ABS',  $GRAY,   [$self => 'key', 8]],
            ['9',   'RMD',     'DBLR', $GRAY,   [$self => 'key', 9]],
            ['/',   'XOR',     'DBL/', $GRAY,   [$self => 'math3', $DV, $XR, $DD]],
        ],
        [
            ['GSB', 'x><(i)',  'RTN',  $GRAY,   [$self => 'err']],
	    ['GTO', 'x><I',    'LBL',  $GRAY,   [$self => 'err']],
            ['HEX', 'Show',    'DSZ',  $GRAY,   [$self => 'err']],
            ['DEC', 'Show',    'ISZ',  $GRAY,   [$self => 'err']],
            ['OCT', 'Show',    'sqrt', $GRAY,   [$self => 'gmath', $SQ]],
            ['BIN', 'Show',    '1/x',  $GRAY,   [$self => 'gmath', $RP]],
            ['4',   'SB',      'SF',   $GRAY,   [$self => 'key', 4]],
            ['5',   'CB',      'CF',   $GRAY,   [$self => 'key', 5]],
            ['6',   'B?',      'F?',   $GRAY,   [$self => 'key', 6]],
            ['x',   'AND',     'DBLx', $GRAY,   [$self => 'math3', $ML, $AN, $DM]],
        ],
    ];

    # Build the leftmost 5 calculator keys of the last 2 rows.

    build_button_rows $self, $frame2, [
        [
            ['R/S', '(i)',     'p/r',  $GRAY,   [$self => 'err']],
	    ['SST', 'I',       'BST',  $GRAY,   [$self => 'err']],
            [$ROLD, 'cPRGM',   $ROLU,  $GRAY,   [$self => 'roll_stack']],
            [$SWAP, 'cREG',    'PSE',  $GRAY,   [$self => 'swapxy']],
            ['BSP', 'cPREFIX', 'CLx',  $GRAY,   [$self => 'bspclx']],
        ],
        [
            ['ON',   '',       '',     $GRAY,   [$self => 'on']],
	    ['f',    '',       '',     $ORANGE, [$self => 'f']],
            ['g',    '',       '',     $BLUE,   [$self => 'g']],
            ['STO', 'WSIZE',   '<',    $GRAY,   [$self => 'err']],
            ['RCL', 'FLOAT',   '>',    $GRAY,   [$self => 'err']],
        ],
    ];

    # The 2 column high ENTER key divides the last 2 rows of calculator keys.

    my $enter = $frame0->Tk::Calculator::RPN::HP::Key3_16C(
        -topl       => 'WINDOW',
        -butl       => "E\nN\nT\nE\nR",
        -botl       => 'LSTx',
        -background => $GRAY,
        -command    => [$self => 'enter'],
        -height     => 6,
    );
    $enter->pack(qw/-side left -expand 1 -fill both/);

    # Build the rightmost 4 calculator keys of the last two rows.

    build_button_rows $self, $frame3, [
        [
            ['1',    '1\'S',   'X<=y', $GRAY,   [$self => 'key', 1]],
            ['2',    '2\'S',   'x<0',  $GRAY,   [$self => 'key', 2]],
            ['3',    'UNSGN',  'x>y',  $GRAY,   [$self => 'key', 3]],
            ['-',    'NOT',    'x>0',  $GRAY,   [$self => 'math3', $SB, undef, undef]],
        ],
        [
            ['0',   'MEM',     'x!=y', $GRAY,   [$self => 'key', 0]],
            ['.',   'STATUS',  'x!=0', $GRAY,   [$self => 'key', '.']],
            ['CHS', 'EEX',     'x=y',  $GRAY,   [$self => 'chs']],
            ['+',   'OR',      'x=0',  $GRAY,   [$self => 'math3', $AD, $IO, undef]],
        ],
    ];

    $self->set_keypad_bindings;
  
    $self->{PB}->set($self->{PB_PERCENT} = 90) if $self->{PB};

} # end Populate

# Function key processors.

sub bspclx {

    my ($self) = @_;

    return unless $self->{ONOFF};
    if ($self->{F_PRESSED}) {
	$self->bell;
	$self->end;
	return;
    }

    if ($self->{G_PRESSED}) {		# CLx
	$self->clx;
    } else {
	if (length($self->{STACK}[0]) <= 2) { # BKSP
	    $self->{STACK}[0] = 0;
	    $self->{CLRX} = 1;
	    $self->{PUSHX} = 0;
	} else {
	    chop $self->{STACK}[0];
	}
	$self->end;
    }

} # end bspclx

sub gmath {
    
    my ($self, $func) = @_;

    return unless $self->{ONOFF};
    if ($self->{G_PRESSED}) {
	$self->math($func);
    } else {
	$self->err;
    }

} # end gmath

sub roll_stack {

    my ($self) = @_;

    return unless $self->{ONOFF};
    if ($self->{F_PRESSED}) {
        $self->bell;
        $self->end;
        return;
    }

    if ($self->{G_PRESSED}) {
        $self->roll_up;
    } else {
	$self->roll_down;
    }

} # end rollstack

1;

=head1 AUTHOR

sol0@Lehigh.EDU

Copyright (C) 2001 - 2007, Steve Lidie. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 KEYWORDS

calculator, HP, RPN, HP 16C

=cut
